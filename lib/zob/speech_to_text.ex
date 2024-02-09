defmodule SpeechToText do
  use Membrane.Filter

  alias Membrane.RawAudio
  require Membrane.Logger

  @vad_chunk_duration Membrane.Time.milliseconds(500)

  def_input_pad(:input,
    accepted_format: %RawAudio{sample_format: :f32le, channels: 1, sample_rate: 16_000}
  )

  def_output_pad(:output, accepted_format: Membrane.RemoteStream)

  def_options(
    chunk_duration: [
      spec: Membrane.Time.t(),
      default: Membrane.Time.seconds(5),
      default_inspector: &Membrane.Time.pretty_duration/1,
      description: """
      The duration of chunks feeding the model.

      Must be at least 5 seconds. The longer the chunks,
      the better transcription accuracy, but bigger latency.
      """
    ],
    vad_threshold: [
      spec: float,
      default: 0.03,
      description: """
      Volume threshold below which the input is considered to be silence.

      Used for optimizing aligment of chunks provided to the model
      and filtering out the silence to prevent hallucinations.
      """
    ]
  )

  @impl true
  def handle_setup(_ctx, options) do
    {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

    serving =
      Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
        defn_options: [compiler: EXLA]
      )

    Membrane.Logger.info("Whisper model ready")

    state =
      Map.merge(options, %{
        serving: serving,
        speech: <<>>,
        queue: <<>>,
        chunk_size: nil,
        vad_chunk_size: nil
      })

    {[], state}
  end

  @impl true
  def handle_stream_format(:input, stream_format, _ctx, state) do
    state = %{
      state
      | chunk_size: RawAudio.time_to_bytes(state.chunk_duration, stream_format),
        vad_chunk_size: RawAudio.time_to_bytes(@vad_chunk_duration, stream_format)
    }

    {[stream_format: {:output, %Membrane.RemoteStream{}}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    input = state.queue <> buffer.payload

    if byte_size(input) > state.vad_chunk_size do
      process_data(input, %{state | queue: <<>>})
    else
      {[], %{state | queue: input}}
    end
  end

  defp process_data(data, state) do
    # Here we filter out the silence at the beginning of each chunk.
    # This way we can fit as much speech in a single chunk as possible
    # and potentially remove whole silent chunks, which cause
    # model hallucinations. If after removing the silence the chunk
    # is not empty but too small to process, we store it in the state
    # and prepend it to the subsequent chunk.
    speech =
      if state.speech == <<>> do
        filter_silence(data, state)
      else
        state.speech <> data
      end

    if byte_size(speech) < state.chunk_size do
      {[], %{state | speech: speech}}
    else
      model_input = Nx.from_binary(speech, :f32)
      result = Nx.Serving.run(state.serving, model_input)
      transcription = Enum.map_join(result.chunks, & &1.text)
      buffer = %Membrane.Buffer{payload: transcription}
      {[buffer: {:output, buffer}], %{state | speech: <<>>}}
    end
  end

  defp filter_silence(samples, state) do
    samples
    |> generate_chunks(state.vad_chunk_size)
    |> Enum.drop_while(&(calc_volume(&1) < state.vad_threshold))
    |> Enum.join()
  end

  defp generate_chunks(samples, chunk_size) when byte_size(samples) >= 2 * chunk_size do
    <<chunk::binary-size(chunk_size), rest::binary>> = samples
    [chunk | generate_chunks(rest, chunk_size)]
  end

  defp generate_chunks(samples, _chunk_size) do
    [samples]
  end

  # Calculates audio volume based on standard deviation
  # of the samples
  defp calc_volume(chunk) do
    samples = for <<sample::float-32-little <- chunk>>, do: sample
    samples_cnt = Enum.count(samples)
    samples_avg = Enum.sum(samples) / samples_cnt
    sum_mean_square = samples |> Enum.map(&((&1 - samples_avg) ** 2)) |> Enum.sum()
    :math.sqrt(sum_mean_square / samples_cnt)
  end
end

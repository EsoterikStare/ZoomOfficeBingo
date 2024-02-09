defmodule Zob.Listener do
  import Membrane.ChildrenSpec
  alias Membrane.RCPipeline

  def start do
    event_handler =
      fn event ->
        IO.inspect(event, label: "listener got event")
        Phoenix.PubSub.broadcast(Zob.PubSub, "new_word", {:new_word, event.payload})
      end

    spec =
      child(%Membrane.PortAudio.Source{channels: 1, sample_format: :f32le, sample_rate: 16_000})
      |> child(SpeechToText)
      |> child(%Membrane.Debug.Sink{handle_buffer: event_handler})

    pipeline = RCPipeline.start_link!()
    RCPipeline.exec_actions(pipeline, spec: spec)
  end
end

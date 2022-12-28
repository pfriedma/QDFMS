defmodule QdfmsWeb.CategoryLive do
  use QdfmsWeb, :live_view
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
          |> assign(:uploaded_files, [])
          |> allow_upload(:icon, accept: ~w(.svg), auto_upload: false)
      }  # add items to assigns
  end

  @impl true
  def handle_event("create_category_new", data, socket) do

    file_data =
      consume_uploaded_entries(socket, :icon, fn %{path: path}, _entry ->
        #dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path)])
        # The `static/uploads` directory must exist for `File.cp!/2` to work.
        #File.cp!(path, dest)
        File.read!(path)
      end)
      IO.puts("File Data:\n")
      IO.puts(Kernel.inspect(file_data))
      {:noreply, socket}
  end


  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"


  @impl true
  def render(assigns) do
    ~H"""
    <div id="new_category_form" >
    <%= f = form_for :category_f, "#", phx_submit: "create_category_new", phx_change: "validate" %>
      <%= label f, :name_f %>
      <%= text_input f, :name_f %>
      <%= label f, :icon_f %>
      <%= live_file_input @uploads.icon %>
    <%= submit "Save", phx_disable_with: "Saving..." %>

    <%= Kernel.inspect(@uploaded_files) %>

</div>


    """
  end








end

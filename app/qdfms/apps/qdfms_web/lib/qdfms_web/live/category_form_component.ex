defmodule CategoryFormComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use QdfmsWeb, :live_component
  alias Database.Category


  def mount(_params, _session, socket) do
    {:ok, socket
          |> allow_upload(:icon, accept: ~w(.svg), auto_upload: false)
      }  # add items to assigns
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}

  end

  def handle_event("save_category", %{"category" => cat_data} = _data, socket) do
    IO.puts("in the component!")
    IO.puts(Kernel.inspect(cat_data))
    file_data =
      consume_uploaded_entries(socket, :icon, fn %{path: path}, _entry ->
        #dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path)])
        # The `static/uploads` directory must exist for `File.cp!/2` to work.
        #File.cp!(path, dest)
        {:ok, Base.encode64(File.read!(path))}
      end)
      encoded_file_data = List.first(file_data)

      if cat_data["id"] == "new" do
        IO.puts("creating a new one...")
        Inventory.Category.create_category(cat_data["name"], encoded_file_data)
        send(self(), {:updated_categories})
        socket = socket
        |> push_event("js-exec", %{id: "#new_category_form"})
        |> put_flash(:info, "Item added!")
        {:noreply, socket}

      else

        IO.puts("updating category "<> cat_data["id"])
        encoded_file_data = if is_nil(encoded_file_data) && cat_data["clear_img"] == "false" do
          #need to get the image data as to not replace it
          get_image_from_db(
            Inventory.Category.get_category(
              String.to_integer(cat_data["id"])
              )
            )
        else
          encoded_file_data
        end
        case Inventory.Category.update_category(
          String.to_integer(cat_data["id"]),
          cat_data["name"],
          encoded_file_data) do
            {:error, reason} ->
              {:noreply,
              socket
              |> put_flash(:info, "ERROR "<> to_string(reason))
              }

            %Category{} = category ->
              send(self(), {:updated_categories})
              {:noreply,
              socket
              |> push_event("js-exec", %{id: "#edit_category_form-#{cat_data[:id]}"})
              |> put_flash(:info, "Category " <> cat_data["name"] <> " added!")
              }

            _ -> {:noreply,
            socket
            |> put_flash(:info, "ERROR - unrecognised response")
            }
          end
      end
  end

  defp get_image_from_db(%Database.Category{} = category) do
    category.image
  end

  def render(assigns) do
    ~H"""
    <div class="category_form">

      <%= f = form_for :category, "#", phx_submit: "save_category", phx_change: "validate", phx_target: @myself %>
      <%= hidden_input f, :id, value: @id %>
      <%= label f, :name, value: @name %>
      <%= text_input f, :name, value: @name %>
      <%= label f, :icon %>
      <%= live_file_input @uploads.icon %>
      <%= unless @id == "new" do%>
        <%= label f, "Clear Image?" %>
        <%= checkbox f, :clear_img %>
      <% end %>
      <%= submit "Save", phx_disable_with: "Saving..." %>


    </div>
    """
  end

end

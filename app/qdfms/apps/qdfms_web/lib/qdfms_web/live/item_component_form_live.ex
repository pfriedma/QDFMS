defmodule ItemComponentFormLive do
  use QdfmsWeb, :live_component


  def handle_event("validate", _data, socket) do
    {:noreply, socket}

  end

  def handle_event("save_item", %{"item" => item_data} = _data, socket) do
    today = Date.utc_today()
    file_data =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        #dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path)])
        # The `static/uploads` directory must exist for `File.cp!/2` to work.
        #File.cp!(path, dest)
        {:ok, Base.encode64(File.read!(path))}
      end)
      encoded_file_data = List.first(file_data)
#def create_item(container, upc, name, description, mfr_exp_date, date_added, weight, photo)
      if item_data["id"] == "new" do
        IO.puts("creating a new one...")
        do_assign_categories(item_data["categories_checkbox_group"])
        #Inventory.Item.create_item(container)
        #send(self(), {:updated_items})
        socket = socket
        |> put_flash(:info, "Device added!")
        {:noreply, socket}
      else
        encoded_file_data = if is_nil(encoded_file_data) && item_data["clear_img"] == "false" do
          #need to get the image data as to not replace it
          get_image_from_db(
            Inventory.Item.get_item(
              String.to_integer(item_data["id"])
              )
            )
        end

      end

    IO.puts(Kernel.inspect(item_data))
    {:noreply, socket}
  end

  defp get_image_from_db(%Database.Item{} = item) do
    item.image
  end

  defp do_assign_categories(cat_list) do

  end


  def render(assigns) do

    ~H"""
    <div class="item_form">

    <%= f = form_for :item, "#",  phx_submit: "save_item", phx_change: "validate", phx_target: @myself %>
      <%= cats = if @id != "new", do: Enum.map(Inventory.Items.get_categories_raw(String.to_integer(@id)), fn %Database.ItemCategory{} = x -> x.category_id end), else: []%>
      <%= hidden_input f, :id, value: @id %>
      <%= hidden_input f, :container, value: @container%>
        <%= label f, :name %>
        <%= text_input f, :name, value: @item.name %>
        <%= error_tag f, :name %>
        <%= unless is_nil(@item.upc) || String.length(@item.upc) == 0 do %>
          <%= label f, :upc  %>
          <%= text_input f, :upc, value: @item.upc %>
          <%= error_tag f, :upc %>
        <% end %>
        <%= label f, :description %>
        <%= text_input f, :description, value: @item.description %>
        <%= error_tag f, :description %>

        <%= label f, :exp_date %>
        <%= date_input f, :exp_date, value: @item.mfr_exp_date %>

        <%= label f, :weight %>
        <%= number_input f, :weight_value, value: @item.weight.value %>
        <%= label f, :units %>
        <%= select f, :units, Enum.map(ExUc.Units.Mass.units, fn {x,y} -> x end), value: @item.weight.unit %>
        <%= #multiple_select(f, :categories_select_multiple, Enum.map(Inventory.Category.get_all_categories(), fn x -> x.id end) ) %>
        <fieldset id="categories_checkbox_group">
        <%= for cat <-  Inventory.Category.get_all_categories() do  %>
            <div class="categories">
            <%= if !is_nil(cat.image) do %>
            <img src={"data:image/svg+xml;base64,#{cat.image}"}, height='60', width='60'/><br/>
            <% end %>
            <input type="checkbox" name="item[categories_checkbox_group][]" value={cat.id} checked={Enum.member?(cats,cat.id)}/><%=cat.name %>
            </div>
        <% end %>
      </fieldset>
      <%= label f, :image %>
      <%= live_file_input @uploads.image %>
      <%= unless @id == "new" do%>
        <%= label f, "Clear Image?" %>
        <%= checkbox f, :clear_img %>
      <% end %>
      <div style="clear:both"></div>

    <%= submit "Save" %>
    </div>
    """
  end


end

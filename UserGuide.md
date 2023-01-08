# QDFMS User Documentation

## Basic Quickstart
This section assumes a configured application. If you haven't set up the app or its dependencies please see [Use and Setup](https://github.com/pfriedma/QDFMS#use-and-setup) before going further. If you haven't configured categories or containers, see [Admin Configuration](#admin-configuration) before proceeding. 

**NOTE**: Sometimes the app doesn't respond appropriately. You can always just refresh the page to get a fresh session. 

### Container Selection
When the app is loaded (or the page refreshed), you'll be prompted to select which container to manage from a drop-down list. Select the container you want, and click the `Manage Container` button. If you want to change containers at any time, just refresh the page, and the app will ask you to select a container to manage. 

### Removing Items

#### Removing via barcode scan
Click `Remove Item` and scan the item you want to remove. If nothing happens, try removing the item again. Sometimes the barcode scanner errors out. 

You'll then see a list of matching items (you might have three of the same product). Select the specific one you want to remove (e.g. by its particular expiry date) and select `remove`. You'll be asked to confirm. 

After you click OK, the item is removed. 

#### Removing without scanning
Click `Remove Item` and then click `Continue without scanning`. Search for the item you want to remove and then proceed as above by clicking `Remove`. 

Alternatively, click `Search`. Search for the item you want to remove and then proceed as above by clicking `Remove`. 

### Adding Items
Click `Add Item` and scan the item into the system. If the add dialog box doesn't come up, try again. You can also click `Continue without scanning` to enter information manually. UPC won't be available in this case, so you shouldn't do this for items that have a barcode. 

**IMPORTANT: Sometimes the scanner mis-reads a barcode. You should always double-check that it was scanned correctly, or it may be more difficult to find later** The error appears to usually be in the first or last 4 digits. 

If product information is already available, it will pre-populate the information except for the expiration date and the product categories (categories should come over but this is a TODO item).

Enter the details of the product (weight must be a whole number), and select any categories you want to tag the item with. Previously selected categories should be pre-checked. If you make changes, those categories selected will be selected next time. 

**IMPORTANT: *ALL FIELDS* are mandatory except image** if you can't find an item expiry date, pick one a year out or something.  

When the item looks correct, click the `Save` button. If you are adding multiple identical items, you can click the button multiple times. This is a ~~bug~~ feature.

### Searching Items
Click `Search` and select any categories you want to filter the items by. There is also case-insensitive search that will search both an item name and its description. 

From the search results screen you can edit and remove items. 

#### Advanced Search
The `Advanced` search function allows you to show items expiring within the next 30 days, or items older than a certain number of days. This function will occasionally cause the app to crash and reload when both options are selected and then changed. If you want to change an advanced search, click the `reset` button first which seems to prevent the crash. 

## Resolving Issues
### I scanned a product and nothing happened
Sometimes the scanner fails and closes before returning a barcode to the system. Scanning itself doesn't do anything to the state of the items (adding and removing need to be user-confirmed) so you can safely just try the operation again. Just click `Add Item` or `Remove Item` to try again. 

This appears to be caused by a race condition. Fix is being worked on. 

If the problem persists, try refreshing the page. 

### The UPC is wrong
Sometimes the barcode scanner is ambitious and doesn't get a barcode right. If you added an item with an incorrect barcode, you'll probably have to remove it manually. You can, of course also modify the UPC on the back end with an iex session, given some item_id:

```
item = Inventory.Items.get_item(item_id)
item = %{item| upc: "the_new_upc"}
Database.Item.write!(item)
Inventory.HistoricalItems.create_from_item(item)
```

### ??? 
When in doubt, refresh the page and start with a fresh session.


## Admin Configuration
Admin configuration is accessed by the `/admin` path (edit the URL in the browser and add `/admin`)

### Containers
Containers are the basic categorization of items. They represent a logical location of items you want to manage like a shelving unit, appliance, cabinet, or room. 

The `Containers` admin scren lets you add new containers. 

To add a container, click `Create new` and name the container. 

Because items are linked to containers they can't be changed in the admin interface. If you really want to delete or rename a container, you can re-name the container, or re-assign the items and delete the container using IEX.

### Categories
The `Categories` screen lets you manage item categories. Categories have a name and an optional icon. To create a new category select `Create new` and select the icon and name. **The form will be cleared when you upload an image so select the file *first* then name it**

To adit a name or icon of a category, click `Edit`. 

### Endpoint devices
This screen lets you manage endpoint devices like tablets, kiosks, etc that are dedicated to a particular container which would bypass container selection on app load. This is not implemented.  

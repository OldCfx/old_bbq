# 🥩 old_bbq

The **old_bbq** script brings a truly immersive barbecue experience to your roleplay server using **ox_inventory** and **ox_lib**.

---

## ✨ Main Features

🔨 **Barbecue Placement**  
- Players can place a real BBQ prop in front of them with an animation directly from their inventory.  
- The BBQ is interactive, and can be dismantled to return as an item in the inventory.  

🔥 **Visual Effects**  
- Realistic fire (toggleable in config).  
- Smoke and particle effects for a lively atmosphere (toggleable in config).  
- Steaks (`prop_cs_steak`) automatically appear on the grill (toggleable in config).  

🍖 **Cooking System**  
- The BBQ generates a **temporary stash** via ox_inventory.  
- Only raw meat can be placed inside.  
- When raw meat is deposited, it is instantly transformed into cooked meat.  

👨‍🍳 **Player Interactions**  
- **E (Cook)** → plays an animation with a spatula attached to the player’s hand and opens the BBQ stash.  
- **G (Pack Up)** → plays a dismantling animation, deletes props and effects, and returns the BBQ item to inventory.  
- **F (Look At)** → activates a cinematic camera focused on the grill.  
  *Press **F** again to exit the camera mode.*  

---

## ⚙️ Configuration (`shared/config.lua`)
- Fully configurable action times (placement, dismantling, cooking).  
- Toggle visual steaks, smoke, and fire.  

---

## 📦 Dependencies
- [ox_inventory](https://github.com/overextended/ox_inventory)  
- [ox_lib](https://github.com/overextended/ox_lib)  

---

## 📑 Required Items

To make the BBQ work, you must add the following items in your **`ox_inventory/data/items.lua`**:

```lua
['barbecue'] = {
    label = 'Barbecue',
    weight = 2000,
    stack = false,
    close = true,
    description = 'Perfect for grilling a good steak',
    client = {
        export = 'old_bbq.place'
    }
},

['rawmeat'] = {
    label = 'Raw Meat',
    weight = 200,
},

['cookedmeat'] = {
		label = 'Cooked meat',
		weight = 200,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
		},
},
```
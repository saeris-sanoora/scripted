# Immutable
by Saeris (saeris@pm.me)
A library for handling immutable Lua values within a World of Warcraft AddOn environment.

[Hosted on GitHub](https://github.com/saeris-sanoora/immutable)


## Installation
To use the library in your project, follow these steps:

1. [Download latest version from Github](https://github.com/saeris-sanoora/immutable/archive/master.zip)
2. Extract the archive and copy the contents into the addon's directory under a `lib/` subdirectory (or wherever you choose to store libraries). Be sure to copy everything, not just the `.lua` file.
3. Add these lines to your addon's `.toc` file:

	lib\LibStub\LibStub.lua
	lib\Immutable-1.0\Immutable.lua

And that's it. The library will load with your addon, and it's accessible as noted below in the Usage section.


## Usage
The library can be accessed through [LibStub](https://www.wowace.com/addons/libstub/) as follows:

```lua
local Immutable = LibStub('Immutable-1.0')
```

The main API is `Immutable.transform(original, change)`.
This takes an original value and a change to apply, then returns a copy of the original value with the change applied. The original value is never altered.

A `change` is any Lua value, but tables and functions are treated specially.

- When `change` is a table, the `original` value is first shallow-copied, and then each key in the `change` table produces a recursive call, `copy[key] = Immutable.transform(original[key], change[key])`. In this way, any number of nested changes may be applied at once. Note that `original` must be a table, and `original[key]` must not be `nil`. To bypass these restrictions, use a change function instead.

- When `change` is a function, it is called with the `original` value and must return a new value without altering the original. These functions can accomplish complex transformations, such as deleting keys, manipulating arrays, treating tables as opaque, and so on. The library provides a number of utilities to create such change functions, or you can write your own.

- When `change` is any other type (not a table or function), the `change` value is returned immediately (since there is no meaningful way to copy or alter a number or string or boolean, obviously).


## API
### newValue = Immutable.transform(original, change)
Given a value and a change, returns a copy of the value with the change applied.

### change = Immutable.assign(value)
Returns a change function which will set a value directly, without giving it special treatment.
This is useful for setting tables opaquely (to avoid iterating their pairs as nested changes).
Likewise, it is useful for setting functions (to avoid calling them as change functions).

### change = Immutable.addKey(value)
Returns a change function which will add a key to a table, with the given value.
This function asserts that the key does not already exist in the table.

### change = Immutable.removeKey()
Returns a change function which will remove a key from a table.
This function asserts that the key exists in the table.

### change = Immutable.insert(value[, index])
Returns a change function which will insert a value at an index in an array table.
This is equivalent to `table.insert`, except the index may be negative to indicate an offset from the end of the array.
This function asserts that the original value is a table and that the index is within bounds.

### change = Immutable.remove(index)
Returns a change function which will remove an index from an array table.
This is equivalent to `table.remove`, except the index may be negative to indicate an offset from the end of the array.
This function asserts that the original value is a table and that the index is within bounds.


## Examples

### Basic Transformation
```lua
originalTable = {
	prop1 = 1,
	nested = {
		prop2 = 2,
		prop3 = 3,
	},
}
change = {
	prop4 = Immutable.addKey(4),
	nested = {
		prop2 = Immutable.deleteKey(),
		prop3 = 3.5,
	},
}
newTable = Immutable.transform(originalTable, change)

-- The transformed table:
newTable = {
	prop1 = 1,
	prop4 = 4,
	nested = {
		prop3 = 3.5,
	},
}
-- Notice that prop2 has been removed, prop3's value has changed, and prop4 has been added.
-- And this assertion will pass!
assert(newTable ~= originalTable)
```

### Opaque Tables
Sometimes you need to treat tables as opaque, simple values instead of iterating them.

```lua
originalTable = {
	prop1 = 1,
	nested = {
		prop2 = 2,
		prop3 = 3,
	},
}
change = {
	nested = Immutable.assign({
		prop4 = 4,
	}),
}
newTable = Immutable.transform(originalTable, change)

-- The transformed table:
newTable:
{
	prop1 = 1,
	nested = {
		prop4 = 4,
	},
}
-- Notice that the "nested" table has been overwritten instead of merged.
```

### Arrays
Sometimes you need to treat tables as arrays, inserting or removing values.

First, here's insertion of a value.

```lua
originalTable = {
	prop1 = 1,
	nested = { 1, 2, 3 },
}
change = {
	nested = Immutable.insert(3, 2.5),
}
newTable = Immutable.transform(originalTable, change)

-- The transformed table:
newTable = {
	prop1 = 1,
	nested = { 1, 2, 2.5, 3 },
}
-- Notice that the value 2.5 has been inserted at index 3 in the "nested" array table.
```

Now, here's removal of a value.

```lua
originalTable = {
	prop1 = 1,
	nested = { 1, 2, 3 },
}
change = {
	nested = Immutable.remove(2),
}
newTable = Immutable.transform(originalTable, change)

-- The transformed table:
newTable = {
	prop1 = 1,
	nested = { 1, 3 },
}
-- Notice that the value at index 2 has been removed in the "nested" array table.
```

### Custom Change Functions
Perhaps you want to apply a change that adds one to a number.

```lua
originalTable = {
	counter = 1,
}
function increment(original)
	return original + 1
end
change = {
	counter = increment,
}
newTable = Immutable.transform(originalTable, change)

-- The transformed table:
newTable = {
	counter = 2,
}
```


## History / Changelog
See [HISTORY.md](./HISTORY.md)


## Linting
The library uses [Luacheck](https://github.com/mpeterv/luacheck) for linting. The utility can be installed through LuaRocks, or alternatively a Windows standalone version is available for download. To lint, run `luacheck .` from the project's root.


## License
[MIT](./LICENSE)

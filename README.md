# Format-Table2

Have you ever found yourself frustrated when using PowerShell's built-in `Format-Table -AutoSize`, only to discover that key properties of your objects are cut off with ellipses? We all love seeing the full picture of our data, and that's exactly where Format-Table2 steps in.

## Why Format-Table2?

When you run commands like:

```powershell
$data | Format-Table -AutoSize
```

Sometimes you get results like this:

![](https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2/blob/main/assets/a.png?raw=true)

You might notice that some properties are truncated or hidden, leaving you with an incomplete view of your objects. `Format-Table2` is designed to rescue you from this limitation by dynamically calculating the perfect column widths based on both headers and cell content. Every piece of your data is displayed clearly - no more guessing or digging for hidden information!

This is how `Format-Table2` presents your data:

![](https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2/blob/main/assets/c.png?raw=true)

Or this:

![](https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2/blob/main/assets/d.png?raw=true)

Or if your terminal is wide enough, you get this:

![](https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2/blob/main/assets/e.png?raw=true)

And all of this is done automatically, without any extra effort on your part. Just pipe your objects into `Format-Table2` and enjoy the full view of your data!


## Features You'll Love

- **Full Visibility:**  
  No more truncated columns! `Format-Table2` ensures that every property is fully visible by calculating optimal widths from your headers and data.

- **Smart Alignment:**  
  Numeric values are elegantly right-aligned while text values remain left-aligned, giving you a clear, aesthetically pleasing layout.

- **Automatic Wrapping:**  
  When the table exceeds your terminal's buffer width, `Format-Table2` automatically splits the table into neatly wrapped blocks. You can even specify columns that should repeat across blocks to maintain context.

- **Performance Focus:**  
  Using efficient collection types and .NET's `StringBuilder`, `Format-Table2` is optimized for performance. Although it may not suit extremely large datasets, it offers smooth and responsive table rendering for everyday use.

## Installation

Clone the repository and import the function into your PowerShell session:

For ongoing use, consider adding the import command to your PowerShell profile.

## How to Use `Format-Table2`

Using `Format-Table2` is as simple as piping objects from any cmdlet. See your data in full detail instantly:

### Basic Usage

```powershell
Get-Process | Select-Object -First 5 | Format-Table2
```

### With Custom Repeated Columns

If you want specific columns (like "Name" and "Id") to be repeated in every wrapped block, just add the `-RepeatColumns` parameter:

```powershell
Get-Process | Select-Object -First 5 | Format-Table2 -RepeatColumns Name, Id
```

This ensures you always have the context you need, even when your table wraps onto multiple lines.

### Alias `ft2`

For convenience, the function also comes with an alias `ft2`. You can use it just like `Format-Table`'s alias `ft`:

```powershell
Get-Process | Select-Object -First 5 | ft2
```


## A Note on Performance

`Format-Table2` leverages dynamic column width calculation and smart alignment to present your full data picture. It is built with efficient collection types and .NET string builders to improve performance. However, while it's perfect for everyday use and moderate-sized datasets, it might not be the best choice for extremely large volumes of data. Use with caution if you're dealing with high-volume outputs.

## Contributing

We believe that great projects are built by a community of passionate users and developers. If you have ideas or improvements, please feel free to fork the repository, submit a pull request, or open an issue. Your contributions and feedback are very welcome!

## License

This project is licensed under the WTFPL License.

## Author

- **Terry Yang (0x7FFFFFFFFFFFFFFF)** - [GitHub](https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2 "GitHub")

---

Don't settle for partial information. Experience data in its entirety with `Format-Table2` and revolutionize the way you view your PowerShell outputs!


# Modelica language support in Atom

Adds syntax highlighting and snippets to Modelica files in [Atom](https://atom.io/ "Atom").

The grammar was partially created using an [automatic conversion](https://discuss.atom.io/t/convert-sublime-grammar-to-atom-grammar/14843) from the [Modelica grammar for Sublime Text by Boris Chumichev](https://github.com/BorisChumichev/modelicaSublimeTextPackage).

## Snippets

Current code shortcuts (type given keyword + tab):

keyword  | description
---      | ---
/*       | for block comments
model    | for model block
function | for function block
record   | for record block
package  | for package block
block    | for block
class    | for class block
for      | for a for loop block
while    | for a while loop block
when     | for a when event block
if       | for a conditional block

## Toggling annotations

Two commands are available to toggle folding of individual annotations or all
annotations:

- `toggleannotations` -- The cursor must be on the first row of the annotation.
- `toggleallannotations` -- Toggles all annotations in the buffer.

## Documentation view

The HTML documentation in a file can be shown with the `toggledocview` command.

## Example

Here is an example showing syntax highlighting, toggling annotations, and
documentation view.

![language-modelica in action](https://github.com/modelica-tools/atom-language-modelica/raw/master/atom-modelica.gif)

## Key mappings

There are no default keymappings included. Here is one suggestion:

```cson
'atom-text-editor[data-grammar="source modelica"]:not([mini])':
  'tab':          'language-modelica:toggleannotations'
  'shift-tab':    'language-modelica:toggleallannotations'
  'ctrl-shift-j': 'language-modelica:toggledocview'
```

`toggleannotations` is a "DWIM" function, meaning if the cursor is not on the
first line of an annotation, the keypress passes through to the next key
mapping assigned. So, when assigned to TAB as above, TAB will still normally
work right for indentation and for completion of snippets and other uses.

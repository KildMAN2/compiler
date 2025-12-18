# Tracing Parser - Learning Tool

This is a special version of the parser that prints **detailed trace information** showing every step of lexical analysis and parsing.

## 📁 Files

- `part2_trace.lex` - Lexer with tracing output
- `part2_trace.y` - Parser with tracing output
- `makefile_trace` - Makefile to build the tracing version
- `trace_output.txt` - Generated trace file (created when you run)

## 🚀 How to Use

### Step 1: Build the Tracing Parser

```bash
make -f makefile_trace
```

This creates the `part2_trace` executable.

### Step 2: Run on Your Input

```bash
./part2_trace < your_file.cmm > output.tree
```

This will:
- Parse your C-- file
- Create `output.tree` with the parse tree
- Create `trace_output.txt` with detailed trace

### Step 3: Read the Trace

Open `trace_output.txt` to see:

1. **LEXER SECTION** - Every token found:
   ```
   [LEXER] Line 1: Found 'void'
           Token Type: VOID
           Creating node: type='void', value='NULL'
           Returning token: VOID
   ```

2. **PARSER SECTION** - Every grammar rule applied:
   ```
   [PARSER REDUCTION #1]
     Rule: TYPE
     Pattern: void
     Description: Void type
   ```

3. **NODE CREATION** - Every tree node built:
   ```
   Action: Creating node (type='DCL', value='NULL')
   Action: Linking sibling id -> :
   ```

## 📝 Example

Try this simple program (`test_simple_demo.cmm`):
```c
void main() {
    x : int;
    x = 5;
}
```

Run:
```bash
./part2_trace < test_simple_demo.cmm > output.tree
cat trace_output.txt
```

## 🎓 Learning Path

### Read the trace file in this order:

1. **LEXER SECTION** (top of file)
   - See how source code → tokens
   - Each token gets a node
   - Watch line numbers increment

2. **PARSER SECTION** (middle)
   - See reductions in order
   - Each reduction applies a grammar rule
   - Watch the tree being built bottom-up

3. **OUTPUT TREE** (`output.tree`)
   - See the final result
   - Compare with trace to understand structure

## 💡 Tips

- **Start small**: Use simple 1-2 line programs
- **Compare**: Look at trace alongside grammar rules in part2_trace.y
- **Track reductions**: Count them - simpler programs = fewer reductions
- **Follow one token**: Pick a token like `x` and follow its journey

## 🔍 Understanding the Trace

### Lexer Output Explained
```
[LEXER] Line 1: Found 'void'
        Token Type: VOID              ← What token category
        Creating node: type='void'    ← Node type field
                      value='NULL'    ← Node value field
        Returning token: VOID         ← Sent to parser
```

### Parser Output Explained
```
[PARSER REDUCTION #5]
  Rule: DCL                           ← Grammar rule name
  Pattern: ID : TYPE                  ← What pattern matched
  Description: Single variable...    ← What it means
  Action: Creating node (type='DCL') ← What node is built
  Action: Linking sibling id -> :    ← How nodes connect
```

## 📊 Reduction Counter

The reduction counter shows parsing order:
- **Low numbers** = Deep in the tree (leaves)
- **High numbers** = High in the tree (root)
- **Last reduction** = PROGRAM rule (the top)

## 🎯 Exercise

Try these increasingly complex programs:

1. **Empty program**: `void main() {}`
2. **One declaration**: `void main() { x : int; }`
3. **Declaration + assignment**: `void main() { x : int; x = 5; }`
4. **Expression**: `void main() { x : int; x = 2 + 3; }`
5. **Control flow**: `void main() { x : int; if x < 5 then x = 10; }`

Watch how the trace grows!

## 🔧 Clean Up

```bash
make -f makefile_trace clean
```

Removes all generated files including trace output.

---

**Happy Learning! Now you can see exactly how your code becomes a parse tree! 🎉**

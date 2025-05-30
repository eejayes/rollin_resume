local lyaml = require("lyaml")

local function multi_print(content)
  print(content)
  tex.print(content)
end

-- Function to load and parse YAML file
local function load_yaml_file(filename)
    -- Read the contents of the file
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file " .. filename)
    end

    local content = file:read("*all")
    file:close()

    -- Parse YAML content
    local data = lyaml.load(content)
    return data
end

local function handle_level(data, index, indentation)
  local formatted_indentation = string.rep(" ", indentation)
  for i = index, #data do
    item_type = type(data[i])
    if item_type == "string" then
      multi_print(formatted_indentation .. "\\item " .. data[i])
    elseif item_type == "table" then
      for kk, vv in pairs(data[i]) do
        multi_print(formatted_indentation .. "\\item " .. kk)
        multi_print(formatted_indentation .. "\\begin{itemize}[itemsep=\\postnesteditemsep, parsep=0pt, topsep=\\postnestingitemtopsep, left=0pt]")
        handle_level(vv, 0, indentation + 4)
        multi_print(formatted_indentation .. "\\end{itemize}")
      end
    end
  end
end


local function cvevent(yaml_data) 
  for _, post in pairs(yaml_data) do
    multi_print("\\vspace{\\postsep/2}")
    multi_print(
      string.format(
        [[
\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} l r}
    \textbf{%s} \textcolor{themecontrastdark}{(%s)}&\textcolor{themecontrastdark}{%s}\\
\end{tabular*}\vspace{-1em}\textcolor{linecol}{\hrule}]], post[3], post[1], post[2] ))
    local item_start_index = 4
    if type(post[item_start_index]) == "table" and post[item_start_index]["Summary"] then

      multi_print(string.format([[\vspace{\posttoptosummary}%s]], post[item_start_index]["Summary"][1]))
      item_start_index = item_start_index + 1
    end
    -- An index exceeding the length of the current processing subject
    -- confirms that there actually are items in the list to process.
    if #post >= item_start_index then
      multi_print("\\begin{itemize}[itemsep=\\posttopitemssep, parsep=0pt, topsep=\\posttitletoitemsep, left=0pt]")
      handle_level(post, item_start_index, 4)
      multi_print("\\end{itemize}")
    end
    multi_print("\\vspace{\\postsep/2}")
  end
end

local function handle_metadata_level(key, value, element, unpack)
  local element_family_flat = flatten_metadata(value, false)
  if unpack then
    multi_print(string.format("\\rarrow{themecontrastdark} \\normalsize{\\textcolor{accent}{%s}} & %s \\\\", key, element_family_flat))
  else
    table.insert(element, string.format("\\textbf{%s}: %s", key, element_family_flat))
  end
end



function flatten_metadata(subject, unpack)
  if type(subject) == "table" then
    if unpack then
      multi_print("\\begin{tabularx}{\\textwidth}{l X}")
    end
    local element = {}
    for k, v in pairs(subject) do
      if type(k) == "number" then
        if type(v) == "table" then
          for ki, vi in pairs(v) do
            handle_metadata_level(ki, vi, element, unpack)
          end
        else
          table.insert(element, v)
        end
      else
        handle_metadata_level(k, v, element, unpack)
      end
    end
    
    if unpack then
      multi_print("\\end{tabularx}")
    end

    return table.concat(element, ", ")
  else
    return subject
  end
end

local function create_profile_header(yaml_data)
  multi_print(string.format(
[[\textcolor{themecontrastlight}{\small{{%s} $\cdot$  %s  $\cdot$ %s  $\cdot$ %s}}\\[1em]
\HUGE{\textcolor{white}{\textsc{%s}} } \textcolor{themelight}{\rule[-1mm]{1mm}{0.9cm}} \HUGE{\textcolor{white}{\textsc{\typeconvention}} }]],
yaml_data['role'], yaml_data['residence'], yaml_data['email'], yaml_data['phone'], yaml_data['name']))
end

local function simple_list(yaml_data)
  multi_print("\\begin{bibsection}")
--  multi_print("\\begin{itemize}")
  for k, v in pairs(yaml_data) do
    multi_print("\\item[] " .. v["author"] .. " " .. v["title"])
  end
--  multi_print("\\end{itemize}")
  multi_print("\\end{bibsection}")
end

--require("lldebugger").start()
local yaml_data = load_yaml_file(spec)

-- Load the YAML file and print the parsed data
if target == "education" or target == "experience" then
  cvevent(yaml_data[target])
elseif target == "metasection" then
  flatten_metadata(yaml_data[target], true)
elseif target == "profile" then
  create_profile_header(yaml_data[target])
elseif target == "summary_statement" then
  multi_print(string.format([[\textcolor{white}{%s}]], yaml_data["profile"]["summary"]))
elseif target == "publications" then
  simple_list(yaml_data[target])
end

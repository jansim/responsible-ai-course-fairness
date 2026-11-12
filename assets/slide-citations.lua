-- Adds every citation key used in the slide decks to `nocite`, so the
-- book's References chapter lists the references of both presentations
-- (the book chapters only embed the slides and cite nothing themselves).

local decks = {
  "1.0-foundations-of-fairness-slides.qmd",
  "2.0-research-findings-slides.qmd",
}

function Meta(meta)
  local seen, keys = {}, {}
  for _, path in ipairs(decks) do
    local fh = io.open(path, "r")
    if fh then
      local text = fh:read("a")
      fh:close()
      -- citation keys: "@key" not preceded by a word character (skips e-mails)
      for key in ("\n" .. text):gmatch("[^%w_]@([%w_][%w_:%-%.]*[%w_])") do
        if not seen[key] then
          seen[key] = true
          table.insert(keys, "@" .. key)
        end
      end
    end
  end
  local existing = meta.nocite and pandoc.utils.stringify(meta.nocite) or ""
  meta.nocite = pandoc.read(existing .. " " .. table.concat(keys, " "), "markdown").blocks[1].content
  return meta
end

--[[
pipeline.lua — expands `::: {.pipeline}` divs into the ML-pipeline diagram.

Every part of the diagram is absolutely positioned in slide coordinates
(1280 × 720) and carries a stable `data-id`, so reveal.js auto-animate can
morph dots, colours, labels, icons and forks between consecutive slides.

Usage (all attributes optional):

  ::: {.pipeline .large nodes="r p b b b b" sizes="1 1.4 1.8 .8 1.4 1.6" icons=true forks=show}
  :::

  variant classes : .large | .compact | .bare | .simple   (default: regular)
  nodes           : six colour codes — k black, r red, b blue, p red+blue
  sizes           : six dot-size multipliers
  icons           : show data / model / decision icons above the line
  forks           : "show" | "hide" (hide = collapsed, for growing them in)
  y, gap         : override line position / label distance below it (px)
]]

local X      = {97, 315, 533, 751, 969, 1187}
local LABELS = {"Data", "(Pre-)<br>Processing", "Model", "Predictions", "Decisions", "Evaluation"}
local DOT    = 32
local LINE   = 6
local WIDTH  = 1280
local BLEED  = 2000   -- line runs this far past both slide edges, so it reaches
                      -- the screen edge at any viewport aspect ratio

local VARIANTS = {
  regular = {y = 562, label = 26, gap = 30},
  large   = {y = 391, label = 26, gap = 32},
  compact = {y = 612, label = 17, gap = 22},
  bare    = {y = 626},
}

-- icon = {file, width, height}; large icons sit above dots, simple ones in a row
local ICONS = {
  [1] = {"data",     48, 64},
  [3] = {"model",    70, 70},
  [5] = {"decision", 120, 44},
}
local SIMPLE = {   -- slide "Not quite that simple": centre x, centre y, scale
  [1] = {404, 423, 1.3},
  [3] = {640, 418, 1.35},
  [5] = {933, 415, 1.3},
}

local COLORS = {k = {k = true}, r = {r = true}, b = {b = true}, p = {r = true, b = true}}

local function words(s, n, default)
  local out = {}
  for w in (s or ""):gmatch("%S+") do out[#out + 1] = w end
  for i = #out + 1, n do out[i] = default end
  return out
end

-- colour shared by two neighbouring nodes (red wins over blue), else black
local function shared(a, b)
  local ca, cb = COLORS[a] or COLORS.k, COLORS[b] or COLORS.k
  if ca.r and cb.r then return "r" end
  if ca.b and cb.b then return "b" end
  return "k"
end

local function single(c) return (c == "p") and "b" or c end

local function span(cls, id, l, t, w, h, extra)
  return string.format(
    '<span class="%s" data-id="%s" style="left:%gpx;top:%gpx;width:%gpx;height:%gpx"%s></span>',
    cls, id, l, t, w, h, extra or "")
end

local function img(cls, id, src, l, t, w, h)
  return string.format(
    '<img class="%s" data-id="%s" src="assets/icons/%s.svg" alt="" style="left:%gpx;top:%gpx;width:%gpx;height:%gpx">',
    cls, id, src, l, t, w, h)
end

local function build(div)
  local variant = "regular"
  for _, c in ipairs(div.classes) do
    if VARIANTS[c] or c == "simple" then variant = c end
  end
  local out = {string.format('<div class="pipeline pipeline-%s" aria-hidden="true">', variant)}

  if variant == "simple" then
    for i, ic in pairs(ICONS) do
      local s = SIMPLE[i]
      local w, h = ic[2] * s[3], ic[3] * s[3]
      out[#out + 1] = img("pl-icon", "pl-icon-" .. ic[1], ic[1], s[1] - w / 2, s[2] - h / 2, w, h)
    end
    for i, x in ipairs({465, 706}) do
      out[#out + 1] = string.format(
        '<svg class="pl-arrow" data-id="pl-arrow-%d" viewBox="0 0 115 20" style="left:%dpx;top:399px;width:115px;height:20px">' ..
        '<path d="M0 10H108M98 2l10 8-10 8" fill="none" stroke="#000" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        i, x)
    end
    out[#out + 1] = "</div>"
    return pandoc.RawBlock("html", table.concat(out, "\n"))
  end

  local v     = VARIANTS[variant]
  local y     = tonumber(div.attributes.y) or v.y
  local nodes = words(div.attributes.nodes, 6, "k")
  local sizes = words(div.attributes.sizes, 6, "1")
  local top   = y - LINE / 2
  local gap   = tonumber(div.attributes.gap) or v.gap

  -- line: lead-in, five segments, lead-out
  out[#out + 1] = span("pl-line c-" .. single(nodes[1]), "pl-line-in", -BLEED, top, X[1] + BLEED, LINE)
  for i = 1, 5 do
    out[#out + 1] = span("pl-line c-" .. shared(nodes[i], nodes[i + 1]), "pl-line-" .. i,
                         X[i], top, X[i + 1] - X[i], LINE)
  end
  out[#out + 1] = span("pl-line c-" .. single(nodes[6]), "pl-line-out", X[6], top, WIDTH + BLEED - X[6], LINE)

  -- forks (drawn below dots)
  local forks = div.attributes.forks
  if forks == "show" or forks == "hide" then
    for i = 1, 6 do
      out[#out + 1] = img("pl-fork", "pl-fork-" .. i, "fork", X[i] - 6, y - 33,
                          forks == "show" and 116 or 0, 62)
    end
  end

  -- dots
  for i = 1, 6 do
    local d = DOT * (tonumber(sizes[i]) or 1)
    out[#out + 1] = span("pl-dot c-" .. nodes[i], "pl-dot-" .. i, X[i] - d / 2, y - d / 2, d, d)
  end

  -- labels
  if v.label then
    for i = 1, 6 do
      out[#out + 1] = string.format(
        '<span class="pl-label" data-id="pl-label-%d" style="left:%gpx;top:%gpx;font-size:%gpx">%s</span>',
        i, X[i] - 110, y + gap, v.label, LABELS[i])
    end
  end

  -- icons above the line
  if div.attributes.icons == "true" then
    for i, ic in pairs(ICONS) do
      out[#out + 1] = img("pl-icon", "pl-icon-" .. ic[1], ic[1], X[i] - ic[2] / 2, y - 26 - ic[3], ic[2], ic[3])
    end
  end

  out[#out + 1] = "</div>"
  return pandoc.RawBlock("html", table.concat(out, "\n"))
end

function Div(div)
  if div.classes:includes("pipeline") and quarto.doc.is_format("revealjs") then
    return build(div)
  end
end

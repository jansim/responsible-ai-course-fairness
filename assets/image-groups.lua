--[[
image-groups.lua — emit the images in `.faces` / `.papers` divs without a
wrapping <p>.

reveal.js auto-animate pairs <p> elements across slides by their text. A
paragraph holding only images has empty text, so e.g. the `.papers` stack on
one slide gets "matched" with the `.faces` row on the next and the faces are
morphed (and collapsed) out of place. Unwrapping the images avoids that; the
images themselves are still matched by `src`.
]]

local GROUPS = {"faces", "papers"}

function Div(div)
  for _, cls in ipairs(GROUPS) do
    if div.classes:includes(cls) then
      div.content = div.content:walk({
        Para = function(p) return pandoc.Plain(p.content) end
      })
      return div
    end
  end
end

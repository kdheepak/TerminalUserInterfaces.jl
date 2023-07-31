Base.@kwdef struct Word
  text::String
  style::Crayon = Crayon()
end

Base.@kwdef struct Paragraph
  block::Block
  words::Vector{Word}
  scroll::Int = 1
  number_of_lines::Ref{Int}
  function Paragraph(block, words, scroll, number_of_lines = Ref{Int}(0))
    if scroll < 1
      scroll = 1
    end
    new(block, words, scroll, number_of_lines)
  end
end

make_words(sentence::String, style = Crayon()) = [Word(word, style) for word in split(sentence)]

function render(p::Paragraph, area::Rect, buf::Buffer)
  render(p.block, area, buf)
  text_area = inner(p.block, area)

  height(text_area) < 1 && return

  lines = split(wrap(join([word.text for word in p.words], " "); width = Int(width(text_area))), "\n")
  p.number_of_lines[] = length(lines)
  word_count = 1
  for (i, line) in enumerate(lines)
    words = split(line)
    if i < p.scroll || (i - p.scroll) >= height(text_area)
      for _ in words
        word_count += 1
      end
      continue
    end
    count = left(text_area)
    for (j, str) in enumerate(words)
      set(buf, count, top(text_area) + i - p.scroll, String(str), p.words[word_count].style)
      count += length(str)
      word_count += 1
      if j != length(words)
        set(buf, count, top(text_area) + i - p.scroll, " ", p.words[word_count].style)
        count += 1
      end
    end
  end

end

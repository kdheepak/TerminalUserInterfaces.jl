const BAR = (
            " ",
            LOWER_ONE_EIGHTH_BLOCK,
            LOWER_ONE_QUARTER_BLOCK,
            LOWER_THREE_EIGHTHS_BLOCK,
            LOWER_HALF_BLOCK,
            LOWER_FIVE_EIGHTHS_BLOCK,
            LOWER_THREE_QUARTERS_BLOCK,
            LOWER_SEVEN_EIGHTHS_BLOCK,
            FULL_BLOCK,
            )

Base.@kwdef struct BarChart
    block::Block
    data::Vector{Tuple{String, Int}}
    width::Int = 0
    gap::Int = 0
end

function draw(bar_chart::BarChart, area::Rect, buf::Buffer)

    draw(bar_chart.block, area, buf)
    chart_area = inner(bar_chart.block, area)

    w = bar_chart.width
    gap = bar_chart.gap
    if w == 0 || gap == 0
        w = ( width(chart_area) ÷ length(bar_chart.data) ) - 1
        gap = 1
    end

    height(chart_area) < 2 && return

    max_data = maximum([v for (_, v) in bar_chart.data])

    data = [Int(round(d * (height(chart_area) - 1) * 8 / max_data, RoundUp)) for (_, d) in bar_chart.data]

    for j in reverse(1:height(chart_area))
        for (i, d) in enumerate(data)

            symbol = d > 8 ? BAR[9] : BAR[Int(round(d / 8, RoundUp)) + 1]

            for x in 1:w

                set(
                    buf,
                    left(chart_area) + (i - 1) * (w + gap) + x,
                    top(chart_area) + j,
                    symbol,
                )

            end

            if d > 8
                d -= 8
            else
                d = 0
            end

            data[i] = d
        end
    end

    data = [Int(round(d * (height(chart_area) - 1) * 8 / max_data, RoundUp)) for (_, d) in bar_chart.data]

    for (i, d) in enumerate(data)
        s = bar_chart.data[i][1]
        if length(s) < w
            set(
                buf,
                left(chart_area) + (i - 1) * (w + gap) + (w ÷ 2) - (length(s) ÷ 2) + 1,
                top(chart_area) + height(chart_area) - d ÷ 8 - 1,
                s,
            )
        end

    end

    # for (i, &(label, value)) in self.data.iter().take(max_index).enumerate() {
    #     if value != 0 {
    #         let value_label = &self.values[i];
    #         let width = value_label.width() as u16;
    #         if width < self.bar_width {
    #             buf.set_string(
    #                 chart_area.left()
    #                     + i as u16 * (self.bar_width + self.bar_gap)
    #                     + (self.bar_width - width) / 2,
    #                 chart_area.bottom() - 2,
    #                 value_label,
    #                 self.value_style,
    #             );
    #         }
    #     }
    #     buf.set_stringn(
    #         chart_area.left() + i as u16 * (self.bar_width + self.bar_gap),
    #         chart_area.bottom() - 1,
    #         label,
    #         self.bar_width as usize,
    #         self.label_style,
    #     );
    # }

end

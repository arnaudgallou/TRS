#' @title Add a tag to a plot
#' @description Add a tag inside the plot region.
#' @param tag Tag to display.
#' @param position Position of the tag. One of `topleft`, `topright`, `bottomleft`,
#'   `bottomright`.
#' @param margin Numeric vector indicating the space between the tag element and
#'   border of the plot region. If two values are passed, the first value defines
#'   the horizontal margin while the second value defines the vertical margin.
#' @param fontface Font face of the tag element.
#' @param geom Name of geom to use for annotation.
#' @param ... Other arguments passed on to [`annotate()`][ggplot2::annotate()].
#' @export
tag <- function(
    tag,
    position = c("topleft", "topright", "bottomleft", "bottomright"),
    margin = NULL,
    fontface = 2,
    geom = "text",
    ...
) {
  if (!is.null(margin)) {
    if (!is.numeric(margin)) {
      abort("`margin` must be a numeric vector.")
    }
    if (length(margin) > 2) {
      abort("`margin` must be a vector of a single or two elements.")
    }
  }
  position <- match.arg(position)
  is_pos_left <- position %in% c("topleft", "bottomleft")
  is_pos_top <- position %in% c("topleft", "topright")
  if (is.null(margin)) {
    margin <- c(
      if (is_pos_left) -.5 else 1,
      if (is_pos_top) 1 else 0
    )
  } else {
    if (length(margin) == 1) {
      margin <- rep(margin, 2)
    }
    margin <- switch(
      position,
      "topleft" = c(-margin[1], 1 + margin[2]),
      "topright" = c(1 + margin[1], 1 + margin[2]),
      "bottomleft" = c(-margin[1], -margin[2]),
      "bottomright" = c(1 + margin[1], -margin[2])
    )
  }
  ggplot2::annotate(
    geom,
    label = tag,
    x = if (is_pos_left) -Inf else Inf,
    y = if (is_pos_top) Inf else -Inf,
    hjust = margin[1],
    vjust = margin[2],
    fontface = fontface,
    ...
  )
}

#' @export
facet_tags <- function(x = Inf, y = Inf, size = 10 / .pt) {
  structure(
    list(x = x, y = y, size = size),
    class = "facet_tags"
  )
}

#' @export
ggplot_add.facet_tags <- function(object, plot, object_name) {
  layout <- ggplot2::ggplot_build(plot)$layout$layout
  data <- mutate(layout, label = letters[row_number()])
  plot +
    ggplot2::geom_text(
      data = data,
      ggplot2::aes(object$x, object$y, label = label, fontface = "bold"),
      inherit.aes = FALSE,
      hjust = 1L,
      vjust = 1L,
      size = object$size
    )
}

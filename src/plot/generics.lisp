(cl:in-package #:vellum.plot)


(defgeneric data-layer (stack))
(defgeneric aesthetics-layer (stack))
(defgeneric scale-layer (stack))
(defgeneric mapping-layer (stack))
(defgeneric geometrics-layer (stack))
(defgeneric statistics-layer (stack))
(defgeneric facets-layer (stack))
(defgeneric coordinates-layer (stack))
(defgeneric x (layer))
(defgeneric y (layer))
(defgeneric z (layer))
(defgeneric color (layer))
(defgeneric shape (layer))
(defgeneric size (layer))
(defgeneric label (layer))
(defgeneric visualize (backend stack destination))
(defgeneric add (stack layer))
(defgeneric layer-category (layer))
(defgeneric height (layer))
(defgeneric width (layer))
(defgeneric x-dtick (layer))
(defgeneric y-dtick (layer))

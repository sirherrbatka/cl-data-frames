(in-package #:cl-df.table)


(defmethod at ((frame standard-table)
               (column symbol)
               (row integer))
  (~> frame header
      (cl-df.header:alias-to-index column)
      (at frame _ row)))


(defmethod at ((frame standard-table)
               (column integer)
               (row integer))
  (check-type column non-negative-integer)
  (check-type row non-negative-integer)
  (let* ((columns (read-columns frame))
         (length (array-dimension columns 0)))
    (unless (< row length)
      (error 'cl-df.header:no-column
             :bounds (iota length)
             :value column))
    (~> (aref columns column)
        (cl-df.column:column-at row))))


(defmethod (setf at) (new-value
                      (frame standard-table)
                      (column symbol)
                      (row integer))
  (setf (at frame (cl-df.header:alias-to-index (header frame)
                                               column)
            row)
        new-value))


(defmethod (setf at) (new-value
                      (frame standard-table)
                      (column integer)
                      (row integer))
  (check-type column non-negative-integer)
  (check-type row non-negative-integer))


(defmethod column-count ((frame standard-table))
  (~> frame header cl-df.header:column-count))


(defmethod row-count ((frame standard-table))
  (~> frame read-columns
      (reduce #'max _ :key #'cl-df.column:column-size
              :initial-value 0)))


(defmethod column-name ((frame standard-table)
                        (column integer))
  (~> frame header
      (cl-df.header:index-to-alias column)))


(defmethod hstack ((frame standard-table)
                   &rest more-frames)
  (push frame more-frames)
  (map nil (lambda (x) (check-type x standard-table))
       more-frames)
  (let* ((header (apply #'cl-df.header:concatenate-headers
                       (mapcar #'header more-frames)))
         (column-count (cl-df.header:column-count header))
         (new-columns (make-array column-count))
         (index 0))
    (iterate
      (for frame in more-frames)
      (for columns = (read-columns frame))
      (iterate
        (for column in-vector columns)
        (setf (aref new-columns index) (cl-ds:replica column t))
        (incf index)))
    (make 'standard-table
          :header header
          :columns new-columns)))

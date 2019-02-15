(in-package #:cl-df.column)


(defmethod column-type ((column sparse-material-column))
  (cl-ds:type-specialization column))


(defmethod column-type ((column fundamental-iterator))
  t)


(defmethod cl-ds:replica ((column sparse-material-column) &optional isolate)
  (check-type isolate boolean)
  (lret ((result (make 'sparse-material-column
                       :column-size (access-column-size column)
                       :root (cl-ds.common.rrb:access-root column)
                       :shift (cl-ds.common.rrb:access-shift column)
                       :size (cl-ds.common.rrb:access-size column)
                       :tail-size (cl-ds.common.rrb:access-tail-size column)
                       :ownership-tag (cl-ds.common.abstract:make-ownership-tag)
                       :tail (and #1=(cl-ds.common.rrb:access-tail column)
                                  (copy-array #1#)))))
    (when isolate
      (cl-ds.common.abstract:write-ownership-tag
       (cl-ds.common.abstract:make-ownership-tag)
       column))))


(defmethod column-at ((column sparse-material-column) index)
  (sparse-material-column-at column index))


(defmethod (setf column-at) (new-value (column sparse-material-column) index)
  (setf (sparse-material-column-at column index) new-value))


(defmethod iterator-at ((iterator sparse-material-column-iterator)
                        column)
  (check-type column integer)
  (bind (((:slots %columns %index %buffers) iterator)
         (buffers %buffers)
         (length (fill-pointer buffers))
         (offset (offset %index)))
    (declare (type vector buffers))
    (unless (< -1 column length)
      (error 'no-such-column
             :bounds `(0 ,length)
             :value column
             :text "There is no such column."))
    (~> %buffers (aref column) (aref offset))))


(defmethod (setf iterator-at) (new-value
                               (iterator sparse-material-column-iterator)
                               column)
  (check-type column integer)
  (bind (((:slots %changes %bitmasks %columns %index %buffers) iterator)
         (buffers %buffers)
         (length (fill-pointer buffers))
         (offset (offset %index))
         (buffer (aref buffers column))
         (old-value (aref buffer offset)))
    (declare (type vector buffers))
    (setf (aref buffer offset) new-value)
    (unless (< -1 column length)
      (error 'no-such-column
             :bounds `(0 ,length)
             :value column
             :text "There is no such column."))
    (unless (eql new-value old-value)
      (setf (~> %changes (aref column) (aref offset)) t))
    new-value))


(defmethod in-existing-content ((iterator sparse-material-column-iterator))
  (< (access-index iterator)
     (reduce #'max
             (read-columns iterator)
             :key #'column-size)))


(defmethod move-iterator
    ((iterator sparse-material-column-iterator)
     times)
  (declare (optimize (debug 3)))
  (check-type times non-negative-fixnum)
  (when (zerop times)
    (return-from move-iterator nil))
  (bind (((:slots %index %stacks %buffers %depth) iterator)
         (index %index)
         (new-index (+ index times))
         (new-depth (~> new-index
                        integer-length
                        (ceiling cl-ds.common.rrb:+bit-count+)
                        1-))
         (promoted (index-promoted index new-index)))
    (unless promoted
      (setf %index new-index)
      (return-from move-iterator nil))
    (change-leafs iterator)
    (reduce-stacks iterator)
    (clear-changes iterator)
    (clear-buffers iterator)
    (move-stacks iterator new-index new-depth)
    (fill-buffers iterator)
    nil))


(defmethod make-iterator ((column sparse-material-column))
  (declare (optimize (debug 3)))
  (cl-ds.dicts.srrb:transactional-insert-tail!
   column (cl-ds.common.abstract:read-ownership-tag column))
  (lret ((result (make 'sparse-material-column-iterator)))
    (vector-push-extend column (read-columns result))
    (vector-push-extend (make-array cl-ds.common.rrb:+maximum-children-count+)
                        (read-buffers result))
    (vector-push-extend (make-array cl-ds.common.rrb:+maximum-children-count+
                                    :initial-element nil
                                    :element-type 'boolean)
                        (read-changes result))
    (setf (access-depth result) (cl-ds.dicts.srrb:access-shift column))
    (vector-push-extend (make-array cl-ds.common.rrb:+maximal-shift+
                                    :initial-element nil)
                        (read-stacks result))
    (initialize-iterator-column column
                                (~> result read-stacks last-elt)
                                (~> result read-buffers last-elt))))


(defmethod column-type ((column sparse-material-column))
  (cl-ds:type-specialization column))


(defmethod column-type ((column fundamental-iterator))
  t)


(defmethod finish-iterator ((iterator sparse-material-column-iterator))
  (iterate
    (with depth = (access-depth iterator))
    (with index = (access-index iterator))
    (for column in-vector (read-columns iterator))
    (for column-size = (column-size column))
    (for shift = (cl-ds.dicts.srrb:access-shift column))
    (for stack in-vector (read-stacks iterator))
    (setf (cl-ds.dicts.srrb:access-tree column) (first-elt stack)
          (cl-ds.dicts.srrb:access-shift column) (max shift depth))
    (for index-bound = (cl-ds.dicts.srrb:scan-index-bound column))
    (setf (cl-ds.dicts.srrb:access-tree-index-bound column) index-bound
          (access-column-size column) (max column-size index)
          (cl-ds.dicts.srrb:access-index-bound column)
          (+ index-bound cl-ds.common.rrb:+maximum-children-count+))))


(defmethod cl-ds:put-back! ((container fundamental-column) item)
  (cl-ds.meta:position-modification #'cl-ds:put-back! container
                                    container nil :value item))


(defmethod cl-ds.meta:make-bucket ((operation cl-ds.meta:grow-function)
                                   (container sparse-material-column)
                                   location
                                   &rest all
                                   &key value)
  (declare (ignore all location))
  (values (cl-ds:force value)
          cl-ds.common:empty-changed-eager-modification-operation-status))


(defmethod cl-ds.meta:grow-bucket ((operation cl-ds.meta:grow-function)
                                   (container sparse-material-column)
                                   bucket
                                   location
                                   &rest all
                                   &key value)
  (declare (ignore all location bucket))
  (values (cl-ds:force value)
          cl-ds.common:empty-changed-eager-modification-operation-status))


(defmethod cl-ds.meta:position-modification ((operation cl-ds.meta:put!-function)
                                             (structure sparse-material-column)
                                             container
                                             position
                                             &rest all
                                             &key value)
  (bind (((:values container status)
          (cl-ds.dicts.srrb:transactional-sparse-rrb-vector-grow
           operation structure container
           (access-column-size structure)
           all value)))
    (when (cl-ds:changed status)
      (incf (access-column-size container)))
    (values container status)))


(defmethod cl-ds.meta:position-modification ((operation cl-ds.meta:grow-function)
                                             (structure sparse-material-column)
                                             container
                                             position
                                             &rest all
                                             &key value)
  (declare (ignore all))
  (check-type position non-negative-integer)
  (when (eql value :null)
    (error 'setting-to-null
           :argument 'value
           :text "Setting content of the column to :null is not allowed. Use ERASE! instead."))
  (bind (((:values result status) (call-next-method)))
    (when (and (cl-ds:changed status)
               (> position (access-column-size structure)))
      (setf (access-column-size structure) (1+ position)))
    (values result status)))


(defmethod cl-ds.meta:position-modification ((operation cl-ds.meta:shrink-function)
                                             (structure sparse-material-column)
                                             container
                                             position
                                             &rest all)
  (declare (ignore all))
  (check-type position non-negative-integer)
  (bind (((:values result status) (call-next-method)))
    (when (and (cl-ds:changed status)
               (= (1+ position) (access-column-size structure)))
      (setf (access-column-size structure) position))
    (values result status)))


(defmethod (setf column-size) (new-size (column sparse-material-column))
  (check-type new-size non-negative-fixnum)
  (let ((current-size (access-column-size column)))
    cl-ds.utils:todo))


(defmethod remove-nulls ((iterator sparse-material-column-iterator))
  (bind (((:slots %index %stacks %buffers %depth) iterator)
         (index %index))
    (remove-nulls-in-trees iterator)
    (concatenate-trees iterator)
    (trim-depth iterator)
    nil
    ))

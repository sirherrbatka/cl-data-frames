(in-package #:cl-df.table)


(defmacro with-table ((table) &body body)
  (once-only (table)
    `(let ((*table* ,table))
       (cl-df.header:with-header ((header ,table))
         ,@body))))
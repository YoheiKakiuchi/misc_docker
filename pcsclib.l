;; g++ -o pcsclib_for_eus.so -fPIC --shared pcsclib.cpp $(pkg-config --cflags libpcsclite) $(pkg-config --libs libpcsclite)

(defcstruct SCARD_READERSTATE
  (szReader   :long)
  (pvUserData :long)
  (dwCurrentState :integer)
  (dwEventState   :integer)
  (cbAtr :integer)
  (rgbAtr :long)
  )

(defvar *SCARD_STATE_UNAWARE*     #x0000) ;;  /**< App wants status */
(defvar *SCARD_STATE_IGNORE*      #x0001) ;;  /**< Ignore this reader */
(defvar *SCARD_STATE_CHANGED*     #x0002) ;;  /**< State has changed */
(defvar *SCARD_STATE_UNKNOWN*     #x0004) ;;  /**< Reader unknown */
(defvar *SCARD_STATE_UNAVAILABLE* #x0008) ;;  /**< Status unavailable */
(defvar *SCARD_STATE_EMPTY*       #x0010) ;;  /**< Card removed */
(defvar *SCARD_STATE_PRESENT*     #x0020) ;;  /**< Card inserted */
(defvar *SCARD_STATE_ATRMATCH*    #x0040) ;;  /**< ATR matches card */
(defvar *SCARD_STATE_EXCLUSIVE*   #x0080) ;;  /**< Exclusive Mode */
(defvar *SCARD_STATE_INUSE*       #x0100) ;;  /**< Shared Mode */
(defvar *SCARD_STATE_MUTE*        #x0200) ;;  /**< Unresponsive card */
(defvar *SCARD_STATE_UNPOWERED*   #x0400) ;;  /**< Unpowered card */

(let ((mod (load-foreign "pcsclib_for_eus.so")))
  (defforeign pcsc-create-pcsclib mod "create_pcsclib" (:integer) :integer)
  (defforeign pcsc-delete-pcsclib mod "delete_pcsclib" (:integer) :integer)
  (defforeign pcsc-canwait mod "canwait_pcsclib" (:integer) :integer)
  (defforeign pcsc-readername mod "readername_pcsclib" (:integer :string :integer) :integer)
  (defforeign pcsc-get-status-change mod "get_status_change_pcsclib" () :integer)
  (defforeign pcsc-get-card-id mod "get_card_id_pcsclib" () :integer)
  ;;
  (defforeign pcsc-initialize-status mod "initialize_status_pcsclib" () :integer)
  (defforeign pcsc-read-status mod "read_status_pcsclib" () :integer)
  )

(defclass pcsclib
  :super propertied-object
  :slots (ptr reader-name card-state)
  )

(defmethod pcsclib
  (:init
   (&optional (index 0))
   (setq ptr (pcsc-create-pcsclib index))
   (if (/= ptr 0) (send self :reader-name))
   self)
  (:delete ()
   (when (/= ptr 0)
     (pcsc-delete-pcsclib ptr)
     (setq ptr 0))
   t)
  (:can-wait ()
   (if (/= ptr 0)
       (if (= (pcsc-canwait ptr) 0) nil t)))
  (:reader-name ()
   (when (/= ptr 0)
     (let (sz)
       (setq sz (pcsc-readername ptr (make-string 0) 0))
       (setq reader-name (make-string (1+ sz)))
       (pcsc-readername ptr reader-name (1+ sz))
       ))
   )
  (:initialize-card-state ()
   (setq card-state (instantiate SCARD_READERSTATE))
   (pcsc-initialize-status reader-name card-state)
   card-state
   )
  (:get-status-change ()
   (let ((res (pcsc-get-status-change ptr card-state)))
     (if (/= res 0)
         (list res (pcsc-read-status card-state))
       (list res nil))))
  (:get-card-id () (pcsc-get-card-id ptr))
  (:wait-and-read-card ()
   (if (not (send self :can-wait))
       (return-from :wait-and-read-card))
   ;;
   (send self :initialize-card-state)
   ;;
   (let (res status)
     (while t
       (setq res (pcsc-get-status-change ptr card-state))
       (when (/= res 0)
         (setq status (pcsc-read-status card-state))
         (cond
          ((logtest status *SCARD_STATE_EMPTY*)
           (warn "card removed~%")
           )
          ((logtest status *SCARD_STATE_PRESENT*)
           (let ((id (pcsc-get-card-id ptr)))
             (warn "card touched / ~X~%" id))
           )
          )
         )
       )
     )
   )
  )
#|
(setq lib (instance pcsclib :init))
(send lib :wait-and-read-card)
|#

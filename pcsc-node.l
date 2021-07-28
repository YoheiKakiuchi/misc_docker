;;!/usr/bin/env roseus
(load "pcsclib.l")

(ros::roseus-add-msgs "std_msgs")

(ros::roseus "pcsc_card" :anonymous nil)

(ros::advertise "~/card_id" std_msgs::Int64)

(setq lib (instance pcsclib :init))

(unless (send lib :can-wait)
  (ros::ros-error ";; device not connecting ??")
  (exit 1))

(send lib :initialize-card-state)

(while (ros::ok)
  (setq *res* (send lib :get-status-change))
  (when (/= (car *res*) 0)
    (setq *status* (cadr *res*))
    (cond
     ((logtest *status* *SCARD_STATE_EMPTY*)
      (ros::ros-warn "card removed")
      (let ((msg (instance std_msgs::Int64 :init :data 0)))
        (ros::publish "~/card_id" msg))
      )
     ((logtest *status* *SCARD_STATE_PRESENT*)
      (let* ((id (send lib :get-card-id))
             (msg (instance std_msgs::Int64 :init :data id)))
        (ros::ros-warn "card touched / ~X" id)
        (ros::publish "~/card_id" msg))
      )
     )
    )
  )

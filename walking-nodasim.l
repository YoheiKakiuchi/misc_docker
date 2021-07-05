;; copy from https://github.com/agent-system/lecture2021/raw/main/walk_tototial/walking-control.l
;; fixed for using *robot-model*
(load "walking-control.l")

;; robot_assembler/sample/kxr_rcb4robots/{kxrl2l6a6h2.roboasm.l, kxrl2l6a6h2.urdf.euscollada.fixed.yaml}
(load "kxrl2l6a6h2.l")

(require "package://eus_animation/euslisp/eus_animation_robot.l")

(if (not (find-package "EUS_ANIM")) (make-package "EUS_ANIM"))

(when (not (ros::rospack-find "eus_animation"))
  (warning-message 1 "eus_animation missing~%")
  (exit -1))

(require "package://eus_animation/euslisp/eus_animation_robot_lib.l")

(defun create-model-and-viewer ()
  (setq *robot* (instance kxrl2l6a6h2-robot :init))
  (send *robot* :newcoords (make-coords))
  (send *robot* :init-pose)
  (send *robot* :fix-leg-to-coords (make-coords))
  (send-all (send *robot* :links) :worldcoords)
  (send-all (send *robot* :links) :analysis-level :coords)
  ;;(send-all (send *robot* :links) :put :collide-vert-mode :use-all)
  ;;(send-all (send *robot* :links) :put :collide-vert-mode :use-bb-bottom)
  (send-all (send *robot* :links) :put :collide-vert-mode :use-qhull)
  (send-all (send *robot* :links) :put :collide-vert-eq-thre 2.0)

  ;;(eus_anim::test-gen-robot "kxrl2l6a6h2")

  (defvar *mviewer*
    (let* ((mviewer (make-irtviewer :title "noda sim View"
                                    :width 600 :height 600
                                    :draw-origin nil :draw-floor (float-vector 0 0 0))))
      (send mviewer :change-background (float-vector 1 1 1))
      (objects (list *robot*))
      (send mviewer :draw-objects)
      mviewer))

  (setq eus_anim::*sim-param*
        (instance eus_anim::sim-param :init
                  (list :name :default
                        :rotor-inertia (* 1e-7 160 160)
                        :contact-kgain 1000.0
                        :contact-dgain 10.0
                        :friction-kgain 500.0
                        :friction-dgain 2.0
                        :friction-mu 0.8
                        :jfric-kgain 100.0
                        :jfric-dgain 1.0
                        :jfric-mu 0.5
                        :jlimit-kgain 100.0
                        :jlimit-dgain 1.0
                        :pos-kgain 500.0
                        :pos-dgain 2.0)
                  ))
  ;; robot mode for walking-control
  (unless (boundp '*robot-model*)
    (setq *robot-model* (instance kxrl2l6a6h2-robot :init)))
  (send *robot-model* :reset-manip-pose)
  (send *robot-model* :fix-leg-to-coords (make-coords))
  (send *robot-model* :move-centroid-on-foot :both (list :rleg :lleg))

  ;;
  (eus_anim::init-simulation)
  )

;; overwrite function in walking-control.l
(defun send-webots ()
  (eus_anim::send-angle-vector
   :av (scale (deg2rad 1) (send *robot-model* :angle-vector))
   :tm (* 0.001 *time_step*) :wait? nil)
  (eus_anim::wait-interpolation :ref-rtf 1000.0)
  )

(defun go-pos-simulation (x y th &key (step-time 30.0)) ;; step-time [ms]
  (setq *time_step* step-time)
  ;;
  (send *robot-model* :reset-manip-pose)
  (send *robot-model* :fix-leg-to-coords (make-coords))
  (send *robot-model* :move-centroid-on-foot :both (list :lleg :rleg))
  ;;
  (eus_anim::reset-simulation
   :init-pose-func
   '(lambda nil (send *robot* :reset-manip-pose)
      (send *robot* :fix-leg-to-coords (make-coords))
      (send *robot* :move-centroid-on-foot :both (list :lleg :rleg))
      ;;(send *robot* :transform (make-coords :pos (float-vector 0 0 100) :rpy (list 0 pi/2 0)))
      (send *robot* :translate (float-vector 0 0 4))
      ))
  ;;
  (go-pos x y th)
  ;;
  (while *is-walking*
    (walking-control (* 1e-3 *time_step*))
    )
  )

(warn "
(create-model-and-viewer)
(go-pos-simulation 0.5 0 0)
")

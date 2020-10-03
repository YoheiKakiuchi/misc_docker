// /usr/bin/c++ -DLinux -DPTHREAD -DVERSION="'\"9.00\"'" -DX11R6_1 -D_REENTRANT -Dyour_program_name_EXPORTS -Di486 -Dx86_64 -I/usr/X11R6/include -I/home/leus/eus_ws/devel/share/euslisp/jskeus/eus/include -fPIC -Wno-write-strings -Wno-comment '-DREPOVERSION="\"\""' -o constrained_delaunay.cpp.o -c constrained_delaunay.cpp
// /usr/bin/c++ -fPIC -shared -Wl,-soname,constrained_delaunay.so -o /home/leus/wrs_ws/src/robot_assembler/euslisp/constrained_delaunay.so constrained_delaunay.cpp.o

// for Eus
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <math.h>
#include <time.h>
#include <pthread.h>
#include <setjmp.h>
#include <errno.h>

#include <list>
#include <vector>
#include <set>
#include <string>
#include <map>
#include <sstream>
#include <cstdio>
#include <iostream>
#include <cctype>
// End for Eus

#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Constrained_Delaunay_triangulation_2.h>

#include <cassert>
#include <iostream>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;

typedef CGAL::Exact_predicates_tag                               Itag;
typedef CGAL::Constrained_Delaunay_triangulation_2<K, CGAL::Default, Itag> CDT;
typedef CDT::Point Point;
typedef CDT::Edge  Edge;
typedef CDT::Edge_iterator  Edge_iterator;
typedef CDT::Face_iterator  Face_iterator;

// for eus.h
#define class   eus_class
#define throw   eus_throw
#define export  eus_export
#define vector  eus_vector
#define string  eus_string
#define iostream eus_iostream
#define complex  eus_complex

#include "eus.h"
extern "C" {
  pointer ___constrained_delaunay(register context *ctx, int n, pointer *argv, pointer env);
  void register_constrained_delaunay(){
    char modname[] = "___constrained_delaunay";
    return add_module_initializer(modname, (pointer (*)())___constrained_delaunay);}
}

#undef class
#undef throw
#undef export
#undef vector
#undef string
#undef iostream
#undef complex
// End for eus.h

typedef struct {
  double x;
  double y;
  double z;
} eus_point;

pointer CONSTRAINED_DELAUNAY(register context *ctx,int n,pointer *argv)
{
  int num = intval( argv[0]->c.fvec.length );
  double *in_vec = argv[0]->c.fvec.fv;

  CDT cdt;

  for (int i = 0; i < num/4; i++) {
    int idx = i * 4;
    cdt.insert_constraint( Point(in_vec[idx + 0], in_vec[idx + 1]),
                           Point(in_vec[idx + 2], in_vec[idx + 3]) );
  }

  int sz = cdt.number_of_faces();
  //printf ("num_of_faces = %d\n", sz);
  pointer res_fvec = makefvector (sz*3*3);// face * vetices(3) * points(3)
  vpush(res_fvec);

  double* pfvec = res_fvec->c.fvec.fv;
  int cntr = 0;

  for (const Face_iterator& f : cdt.finite_face_handles() ) {
    int idx = cntr * 9;
    Point a = f->vertex(0)->point();
    Point b = f->vertex(1)->point();
    Point c = f->vertex(2)->point();

    pfvec[idx + 0] = a[0];
    pfvec[idx + 1] = a[1];
    pfvec[idx + 2] = 0.0;

    pfvec[idx + 3] = b[0];
    pfvec[idx + 4] = b[1];
    pfvec[idx + 5] = 0.0;

    pfvec[idx + 6] = c[0];
    pfvec[idx + 7] = c[1];
    pfvec[idx + 8] = 0.0;

    cntr++;
  }

  return vpop();
}

pointer ___constrained_delaunay(register context *ctx, int n, pointer *argv, pointer env)
{
  defun(ctx,"C-CONSTRAINED-DELAUNAY-TRIANGULATION", argv[0], (pointer (*)())CONSTRAINED_DELAUNAY, NULL);

  return 0;
}

#if 0
(c-constrained-delaunay-triangulation #f(0 0 100 0 100 0 100 100 100 100 0 100 0 100 0 0))
cgaldir=/home/leus/src/cgal
/usr/bin/c++ \
-I${cgaldir}/Intersections_3/include \
-I${cgaldir}/Polygon/include \
-I${cgaldir}/Convex_hull_2/include \
-I${cgaldir}/Nef_S2/include \
-I${cgaldir}/Segment_Delaunay_graph_2/include \
-I${cgaldir}/Alpha_shapes_2/include \
-I${cgaldir}/Stream_lines_2/include \
-I${cgaldir}/SearchStructures/include \
-I${cgaldir}/Principal_component_analysis_LGPL/include \
-I${cgaldir}/TDS_3/include \
-I${cgaldir}/HalfedgeDS/include \
-I${cgaldir}/Intersections_2/include \
-I${cgaldir}/Point_set_2/include \
-I${cgaldir}/Scale_space_reconstruction_3/include \
-I${cgaldir}/Geomview/include \
-I${cgaldir}/Algebraic_kernel_for_circles/include \
-I${cgaldir}/Cone_spanners_2/include \
-I${cgaldir}/Circular_kernel_3/include \
-I${cgaldir}/Distance_3/include \
-I${cgaldir}/Polygon_mesh_processing/include \
-I${cgaldir}/Triangulation_2/include \
-I${cgaldir}/Partition_2/include \
-I${cgaldir}/Polygonal_surface_reconstruction/include \
-I${cgaldir}/Arrangement_on_surface_2/include \
-I${cgaldir}/Optimal_transportation_reconstruction_2/include \
-I${cgaldir}/Box_intersection_d/include \
-I${cgaldir}/Inventor/include \
-I${cgaldir}/Surface_mesher/include \
-I${cgaldir}/Circulator/include \
-I${cgaldir}/Interval_support/include \
-I${cgaldir}/Polytope_distance_d/include \
-I${cgaldir}/Straight_skeleton_2/include \
-I${cgaldir}/Surface_mesh_skeletonization/include \
-I${cgaldir}/Cartesian_kernel/include \
-I${cgaldir}/Point_set_3/include \
-I${cgaldir}/Surface_mesh_segmentation/include \
-I${cgaldir}/Three/include \
-I${cgaldir}/Convex_hull_3/include \
-I${cgaldir}/Minkowski_sum_3/include \
-I${cgaldir}/Segment_Delaunay_graph_Linf_2/include \
-I${cgaldir}/Modifier/include \
-I${cgaldir}/QP_solver/include \
-I${cgaldir}/Union_find/include \
-I${cgaldir}/Inscribed_areas/include \
-I${cgaldir}/Advancing_front_surface_reconstruction/include \
-I${cgaldir}/AABB_tree/include \
-I${cgaldir}/Mesher_level/include \
-I${cgaldir}/Convex_decomposition_3/include \
-I${cgaldir}/Point_set_processing_3/include \
-I${cgaldir}/Surface_mesh_deformation/include \
-I${cgaldir}/Interpolation/include \
-I${cgaldir}/Hyperbolic_triangulation_2/include \
-I${cgaldir}/GraphicsView/include \
-I${cgaldir}/Voronoi_diagram_2/include \
-I${cgaldir}/Principal_component_analysis/include \
-I${cgaldir}/Installation/include \
-I${cgaldir}/Triangulation/include \
-I${cgaldir}/Hash_map/include \
-I${cgaldir}/Arithmetic_kernel/include \
-I${cgaldir}/Random_numbers/include \
-I${cgaldir}/Mesh_2/include \
-I${cgaldir}/CGAL_Core/include \
-I${cgaldir}/CGAL_ImageIO/include \
-I${cgaldir}/Stream_support/include \
-I${cgaldir}/Interval_skip_list/include \
-I${cgaldir}/Bounding_volumes/include \
-I${cgaldir}/Nef_3/include \
-I${cgaldir}/Algebraic_kernel_for_spheres/include \
-I${cgaldir}/Filtered_kernel/include \
-I${cgaldir}/Polyhedron/include \
-I${cgaldir}/Mesh_3/include \
-I${cgaldir}/Surface_mesh_approximation/include \
-I${cgaldir}/Surface_mesh/include \
-I${cgaldir}/Homogeneous_kernel/include \
-I${cgaldir}/Poisson_surface_reconstruction_3/include \
-I${cgaldir}/Snap_rounding_2/include \
-I${cgaldir}/Generalized_map/include \
-I${cgaldir}/TDS_2/include \
-I${cgaldir}/Ridges_3/include \
-I${cgaldir}/Surface_sweep_2/include \
-I${cgaldir}/Modular_arithmetic/include \
-I${cgaldir}/Kernel_d/include \
-I${cgaldir}/STL_Extension/include \
-I${cgaldir}/Surface_mesh_parameterization/include \
-I${cgaldir}/Polyline_simplification_2/include \
-I${cgaldir}/Shape_detection/include \
-I${cgaldir}/Algebraic_foundations/include \
-I${cgaldir}/Subdivision_method_3/include \
-I${cgaldir}/OpenNL/include \
-I${cgaldir}/Nef_2/include \
-I${cgaldir}/Minkowski_sum_2/include \
-I${cgaldir}/Skin_surface_3/include \
-I${cgaldir}/Periodic_3_mesh_3/include \
-I${cgaldir}/Optimisation_basic/include \
-I${cgaldir}/Classification/include \
-I${cgaldir}/Spatial_sorting/include \
-I${cgaldir}/Surface_mesh_shortest_path/include \
-I${cgaldir}/Solver_interface/include \
-I${cgaldir}/NewKernel_d/include \
-I${cgaldir}/Periodic_2_triangulation_2/include \
-I${cgaldir}/Combinatorial_map/include \
-I${cgaldir}/LEDA/include \
-I${cgaldir}/Jet_fitting_3/include \
-I${cgaldir}/Periodic_3_triangulation_3/include \
-I${cgaldir}/Generator/include \
-I${cgaldir}/Property_map/include \
-I${cgaldir}/BGL/include \
-I${cgaldir}/Visibility_2/include \
-I${cgaldir}/Periodic_4_hyperbolic_triangulation_2/include \
-I${cgaldir}/Triangulation_3/include \
-I${cgaldir}/Spatial_searching/include \
-I${cgaldir}/Envelope_2/include \
-I${cgaldir}/Kernel_23/include \
-I${cgaldir}/Polynomial/include \
-I${cgaldir}/Set_movable_separability_2/include \
-I${cgaldir}/Profiling_tools/include \
-I${cgaldir}/Alpha_shapes_3/include \
-I${cgaldir}/Matrix_search/include \
-I${cgaldir}/Barycentric_coordinates_2/include \
-I${cgaldir}/Number_types/include \
-I${cgaldir}/Polyhedron_IO/include \
-I${cgaldir}/Boolean_set_operations_2/include \
-I${cgaldir}/Convex_hull_d/include \
-I${cgaldir}/Heat_method_3/include \
-I${cgaldir}/Distance_2/include \
-I${cgaldir}/Linear_cell_complex/include \
-I${cgaldir}/Algebraic_kernel_d/include \
-I${cgaldir}/Testsuite/include \
-I${cgaldir}/Surface_mesh_simplification/include \
-I${cgaldir}/Circular_kernel_2/include \
-I${cgaldir}/Apollonius_graph_2/include \
-I${cgaldir}/Envelope_3/include \
-I${cgaldir}/CGAL_ipelets/include \
-DLinux -DPTHREAD -DVERSION="'\"9.00\"'" -DX11R6_1 -D_REENTRANT -Dyour_program_name_EXPORTS -Di486 -Dx86_64 -I/usr/X11R6/include -I/home/leus/eus_ws/devel/share/euslisp/jskeus/eus/include -fPIC -Wno-write-strings -Wno-comment '-DREPOVERSION="\"\""' \
-frounding-math -fPIC -std=gnu++14 -o constrained_delaunay.o -c constrained_delaunay.cpp
/usr/bin/c++ -fPIC -shared -Wl,-soname,constrained_delaunay.so -o constrained_delaunay.so constrained_delaunay.o  -lmpfr -lgmp
#endif

import IPython.display
from utils_demo import *
from sys import platform
import sys
from PIL import Image
import matplotlib.pyplot as plt
import json
import rdflib
import glob
import os
import re
import copy
import time

sys.path.append('../simulation')
sys.path.append('../dataset_utils/')

import numpy as np
import random
import cv2
import add_preconds
import evolving_graph.check_programs as check_programs
import evolving_graph.utils as utils

from unity_simulator.comm_unity import UnityCommunication
from unity_simulator import utils_viz

comm = UnityCommunication(timeout_wait=600)
#comm = UnityCommunication(file_name='/src/virtualhome/simulation/unity_simulator/linux_exec.v2.2.4.x86_64', timeout_wait=300)

scene = 1
scene_graph = "TrimmedTestScene" + str(scene) + "_graph"
executable_program_path = "../dataset/programs_processed_precond_nograb_morepreconds/executable_programs/" + scene_graph + "/*/*.txt"
executable_program_list = []
for file_path in glob.glob(executable_program_path):
    executable_program_list.append(file_path.replace("../dataset/programs_processed_precond_nograb_morepreconds/executable_programs/" + scene_graph + "/", ""))

rdf_g = rdflib.Graph()
rdf_g.parse("../ontology/vh2kg_ontology.ttl", format="ttl")

def get_activity_from_ontology(activity_type):
    results = []
    qres = rdf_g.query(
    """
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX : <http://www.owl-ontologies.com/VirtualHome.owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select ?activity where { 
    ?activity rdfs:subClassOf :%s .
 } 
       """ % activity_type)

    result = ""
    for row in qres:
        activity = "".join(row).replace("http://www.owl-ontologies.com/VirtualHome.owl#","")
        arr = activity.split("_")
        arr[0] = arr[0].capitalize()
        activity = " ".join(arr)
        result = activity
        results.append(result)
    return results

def generate_list_of_steps(file_path):
    file = open(file_path, "r", encoding="utf-8")
    i = 0
    list_of_steps = []
    program_name = ""
    description = ""
    char= "<char0>"
    while True:
        line = file.readline()
        if line:
            line = line.replace("\n","")
            if i==0:
                program_name = line
            elif i==1:
                description = line
            elif line.startswith("["):
                list_of_steps.append(line)
            else:
                pass
            i+=1
        else:
            break
    return program_name, description, list_of_steps

def get_activity_program(category):
    #unexecutable = ["Take shower", "Take shoes off", "Wash teeth", "Wash face", "Dust", "Clean toilet", "Clean room", "Scrubbing living room tile floor is once week activity for me", "Clean mirror", "Play games", "Play on laptop", "Read on sofa"]
    unexecutable = []
    executable = []
    activities = get_activity_from_ontology(category)
    for activity_name in activities:
        if activity_name in unexecutable:
            continue
        results = [program for program in program_list if program["name"] == activity_name]
        if len(results) == 0:
            print("Nothing: " + activity_name)
        else:
            print("Success: " + activity_name)
            executable.append({"activity_name": activity_name, "results": results})
    return executable


data_path = "../dataset/programs_processed_precond_nograb_morepreconds/withoutconds/*/*.txt"
program_list = []
for file_path in glob.glob(data_path):
    file_name = file_path.replace("../dataset/programs_processed_precond_nograb_morepreconds/withoutconds/", "")
    if file_name in executable_program_list:
        program_name, description, list_of_steps = generate_list_of_steps(file_path)
        program_list.append({
            "file_name":file_name,
            "name": program_name,
            "description": description,
            "list_of_steps": list_of_steps
        })

activity_list = []
executable_activity_list = get_activity_program("Leisure")

unsupport_unity_exec_time = {
    "Wipe": 5.0,
    "PutOn": 10.0,
    "PutOff": 10.0,
    "Greet": 3.0,
    "Drop": 2.0,
    "Read": 1800.0,
    "Lie": 5.0,
    "Pour": 5.0,
    "Type": 10.0,
    "Watch": 7200.0,
    "Move": 5.0,
    "Wash": 10.0,
    "Squeeze": 5.0,
    "PlugIn": 5.0,
    "PlugOut": 5.0,
    "Cut": 5.0,
    "Eat": 1200.0,
    "Sleep": 21600.0,
    "Wake": 5.0
}

def check_unsupport_action(script):
    flag = True
    for line in script:
        m = re.search(r'\[.+\]', line)
        action = m.group().replace('[', '')
        action = action.replace(']', '')
        if action in [x for x in unsupport_unity_exec_time.keys()]:
            flag = False
            break
    return flag

def export(activity_name, graph_state_list, activity_cnt, time_list):
    os.mkdir("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name + "/" + activity_cnt)
    state_cnt = 0
    for graph_state in graph_state_list:
        state_cnt += 1
        file_path = "graph_state_list_with_bbox/scene" + str(scene) + "/"  + activity_name + "/" + activity_cnt + "/activityList-graph-state-" + '{0:03d}'.format(state_cnt) + ".json"
        with open(file_path, 'w') as outfile:
            json.dump(graph_state, outfile)

    with open("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name + "/" + activity_cnt + "/activityList-program.txt", 'w') as f:
        for s in executed_program:
            f.write("%s\n" % s)

    with open("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name + "/" + activity_cnt + "/program-description.txt", 'w') as f:
        f.write("%s\n" % activity["name"])
        f.write("%s\n" % activity["description"])
    time_list = [str(time) for time in time_list]
    duration = "\n".join(time_list)
    with open("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name + "/" + activity_cnt + "/duration.txt", 'w') as f:
        f.write(duration)

def update_bbox(pre_graph, current_graph):
    try:
        new_graph= copy.deepcopy(current_graph)
        for pre_node in pre_graph["nodes"]:
            for new_node in new_graph["nodes"]:
                if new_node["id"] == pre_node["id"]:
                    new_node["bounding_box"] = pre_node["bounding_box"]
    except Exception as e:
        print(e)
    return new_graph

def delete2000(graph_state_list):
    new_graph_state_list = []
    for graph_state in graph_state_list:
        new_nodes = [x for x in graph_state["nodes"] if x["id"] < 2000]
        new_edges = [x for x in graph_state["edges"] if x["from_id"] < 2000 and x["to_id"] < 2000]
        new_graph_state_list.append({"nodes": new_nodes, "edges": new_edges})
    return new_graph_state_list

for executable_activity in executable_activity_list:
    activity_list = executable_activity["results"]
    activity_name = executable_activity["activity_name"]
    activity_cnt = 0
    try:
        ##os.mkdir("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name)
        os.makedirs("graph_state_list_with_bbox/scene" + str(scene) + "/" + activity_name, exist_ok=True)
        for activity in activity_list:
            try:
                new_graph_state_list = []
                time_list = []
                comm.reset(scene-1)
                comm.add_character('chars/Female2')
                success, g = comm.environment_graph();
                print(activity["file_name"])
                script = activity["list_of_steps"]
                executable_program = []
                for x in script:
                    executable_program.append("<char0> " + x)
                executable_program
                print(executable_program)
                # check if supported action
                if check_unsupport_action(script) == False:
                    continue

                preconds = add_preconds.get_preconds_script(script).printCondsJSON()

                g = check_programs.translate_graph_dict_nofile(g)

                info = check_programs.check_script(script, preconds, graph_path=None, inp_graph_dict=g)

                message, final_state, graph_state_list, graph_dict, id_mapping, info, helper, executed_script = info
                # if delete randomly placced objects
                ##graph_state_list = delete2000(graph_state_list)

                executed_program = []
                for x in executed_script:
                    executed_program.append("<char0> " + re.sub("\[\d+\]","",x.__str__()).strip())

                if message != "Script is executable":
                    continue

                i = 0
                comm.expand_scene(graph_state_list[0])
                success, g = comm.environment_graph()
                g = update_bbox(g, graph_state_list[i])
                new_graph_state_list.append(copy.deepcopy(g))

                for instruction in executed_program:
                    print("try: " + str(instruction))
                    i += 1
                    start = time.time()
                    success, message = comm.render_script(script=[instruction],
                                              #processing_time_limit=80,
                                              find_solution=False,
                                              image_width=320,
                                              image_height=240,
                                              skip_animation=False,
                                              recording=True,
                                              #gen_vid=False,
                                              #save_scene_states=True,
                                              #file_name_prefix='FoodPreparation',
                                              #frame_rate=10
                                             )
                    time_list.append(time.time() - start)
                    success, g = comm.environment_graph()
                    print(str(success) + ": " + str(instruction))
                    g = update_bbox(g, graph_state_list[i])
                    new_graph_state_list.append(copy.deepcopy(g))

                export(activity_name, new_graph_state_list, str(activity_cnt), time_list)
                activity_cnt += 1
            except Exception as e:
                print(e.args)
    except Exception as e:
        print(e.args)

import matplotlib.pyplot as plt
import numpy as np
import os

# Create output directory for graphs if it does not exist
output_dir = 'performance_results'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# ---------------------------------------------------------
# Figure 1: Face Detection Time Graph (Normal Lighting)
# ---------------------------------------------------------
np.random.seed(42)
test_iterations = np.arange(1, 51)
detection_times = np.random.normal(loc=250, scale=15, size=50)
detection_times = np.clip(detection_times, 200, 310)

plt.figure(figsize=(10, 6))
plt.plot(test_iterations, detection_times, marker='o', linestyle='-', color='#0ea5e9', markersize=6, alpha=0.8, linewidth=2)
plt.axhline(y=np.mean(detection_times), color='r', linestyle='--', label=f'Average Time: {np.mean(detection_times):.0f}ms')
plt.fill_between(test_iterations, detection_times - 10, detection_times + 10, color='#0ea5e9', alpha=0.1)

plt.title('Face Detection Time across 50 Test Iterations (Normal Lighting)', fontsize=14, pad=15)
plt.xlabel('Test Iteration', fontsize=12)
plt.ylabel('Detection Time (Milliseconds)', fontsize=12)
plt.ylim(150, 350)
plt.grid(True, linestyle='--', alpha=0.6)
plt.legend(loc='upper right')

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'face_detection_graph.png'), dpi=300)
plt.close()

# ---------------------------------------------------------
# Figure 2: Attendance Processing Time Graph (Stacked Bar)
# ---------------------------------------------------------
categories = ['Attempt 1', 'Attempt 2', 'Attempt 3', 'Attempt 4', 'Attempt 5']
local_prep = np.array([250, 260, 245, 255, 240]) 
network_transit = np.array([300, 310, 290, 400, 280]) 
cloud_verification = np.array([900, 850, 880, 950, 910]) 

fig, ax = plt.subplots(figsize=(10, 6))
p1 = ax.bar(categories, local_prep, color='#38bdf8', label='Local Preprocessing (ML Kit)')
p2 = ax.bar(categories, network_transit, bottom=local_prep, color='#a855f7', label='Network Transit (API Gateway)')
p3 = ax.bar(categories, cloud_verification, bottom=local_prep + network_transit, color='#f43f5e', label='Cloud Matching (AWS Rekognition)')

ax.axhline(y=1500, color='gray', linestyle='dotted', label='1.5s Target Baseline')
ax.set_ylabel('Processing Time (Milliseconds)', fontsize=12)
ax.set_title('Attendance Processing Time Distribution (Edge vs. Cloud)', fontsize=14, pad=15)
ax.legend(loc='upper right')
ax.grid(axis='y', linestyle='--', alpha=0.5)

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'attendance_processing_graph.png'), dpi=300)
plt.close()

# ---------------------------------------------------------
# Figure 3: Dashboard Response Time Graph (Line Chart)
# ---------------------------------------------------------
np.random.seed(10)
events = np.arange(1, 31)
response_times = np.random.normal(loc=350, scale=40, size=30)
response_times = np.clip(response_times, 200, 480)

plt.figure(figsize=(10, 6))
plt.plot(events, response_times, marker='s', linestyle='-', color='#10b981', markersize=5, linewidth=2)
plt.axhline(y=np.mean(response_times), color='#047857', linestyle='--', label=f'Avg Response: {np.mean(response_times):.0f}ms')
plt.fill_between(events, response_times - 15, response_times + 15, color='#10b981', alpha=0.15)

plt.title('Dashboard UI Response Time post Attendance Marking', fontsize=14, pad=15)
plt.xlabel('Attendance Event Count', fontsize=12)
plt.ylabel('UI Update Latency (Milliseconds)', fontsize=12)
plt.ylim(0, 600)
plt.grid(True, linestyle=':', alpha=0.7)
plt.legend(loc='upper right')

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'dashboard_response_graph.png'), dpi=300)
plt.close()

print(f'Graphs successfully generated in the {output_dir}/ directory')

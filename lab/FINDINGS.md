# Findings — Part 4 debug lab

Fill in one entry per defect you find. Paste the *actual* output you saw —
we cross-check it against your session recording and your git diff, and the
diagnostic path matters more to us than the fix itself.

Before you start investigating, begin recording:
`script -q part4-session.log` (or `asciinema rec part4-session.cast`), and
commit that file alongside this one.

---

## Defect 1

**Symptom** (what you observed — paste the real command output):

helm install demo-chart broken-chart/
Error: INSTALLATION FAILED: server-side apply failed for object default/migrate batch/v1, Kind=Job: Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never

**Cause** (the actual root cause, not the symptom restated):

**Fix** (what you changed, and why this over alternatives):

**How I found it** (the sequence of commands/reasoning that led you here):

---

## Defect 2

**Symptom:**
Warning  Failed     1s (x4 over 30s)  kubelet            spec.containers{backend}: Error: container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root (pod: "backend-7948fd6b4b-c57mp_default(7c1cf820-37de-4abe-ba11-0cc857acf269)", container: backend)
**Cause:**

**Fix:**
runAsUser: 65532
**How I found it:**

---

## Defect 3

**Symptom:**
maximum cpu usage per Container is 1, but request is 2
**Cause:**
values.yaml set metrics requests.cpu=2 / limits.cpu=4. The namespace LimitRange (cluster-state/limits.yaml) caps cpu at "1" per container. Admission rejects the Pod.
**Fix:**
Lowered metrics resources in values.yaml to requests 50m/64Mi, limits 200m/128Mi (same as the other workloads). Respects the LimitRange while keeping explicit requests/limits.
**How I found it:**
verify showed metrics 0/1. describe/events pointed at the LimitRange. Compared with cluster-state/limits.yaml.
---

## Defect 4

**Symptom:**
Reporter can't list the pods

**Cause:**
Rolebinding in rbac.yaml had the name 'default' instead of 'reporter'

**Fix:**
Set the name to reporter in subjects

**How I found it:**
verify's can-i check failed. Inspected templates/rbac.yaml and compared with values.reporter.serviceAccountName and the ServiceAccount manifest.

---

## Defect 5

**Symptom:**
./scenario.sh verify
  FAIL  gateway /status does not report backend=ok

**Cause:**
values.yaml had BACKEND_URL: "http://backend.default.svc:8080". The release lives in namespace debug-lab, so the backend Service is not in default. The gateway could not reach it.

**Fix:**
Set BACKEND_URL to "http://backend:8080" (same-namespace short name). Portable and correct for any release namespace.

**How I found it:**
backend Deployment was Ready and answered /healthz, yet gateway reported backend=fail. Checked the Service location vs the hardcoded URL in values.

---

## Defect 6

**Symptom:**
container has runAsNonRoot and image will run as root (or equivalent non-numeric user error)

**Cause:**
All containers set runAsNonRoot: true but never set runAsUser. When the image does not declare a numeric non-root USER, kubelet refuses to start the container. This is often masked while LimitRange / invalid Job prevent pods from being created.


**Fix:**
setting the runAsUser: 65532, so the pod spec is self-describing and independent of image metadata.


**How I found it:**
After the other four admission / config defects were cleared, remaining pods still failed to start. describe pod showed the runAsNonRoot runtime error. All templates shared the same securityContext pattern without a UID.

---

If you ran out of time on any defect, say so here and describe what you would
have tried next — that section is read carefully and counts in your favour.

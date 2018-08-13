#!/usr/bin/groovy

node {
  def app



  def pwd = pwd()
  def tool_name="moloch"
  def container_dir = "$pwd/container/"
  def custom_image = "images.moloch"
  def custom_values_url = "http://repos.sealingtech.com/cisco-c240-m5/moloch/values.yaml"
  def user_id = ''
  wrap([$class: 'BuildUser']) {
      echo "userId=${BUILD_USER_ID},fullName=${BUILD_USER},email=${BUILD_USER_EMAIL}"
      user_id = "${BUILD_USER_ID}"
  }

  sh "env"

  def container_tag = "gcr.io/edcop-dev/$user_id-$tool_name"

  stage('Clone repository') {
      /* Let's make sure we have the repository cloned to our workspace */
      checkout scm
  }

  stage('helm lint') {
      sh "helm lint $tool_name"
  }

  stage('helm deploy') {
      sh "helm install --name='$user_id-$tool_name-$env.BUILD_ID' -f $custom_values_url $tool_name"
  }

  stage('sleeping 4 minutes') {
    sleep(240)
  }

  stage('Verifying running pods') {
    /* Master (Viewer) */
    def master_number_scheduled=sh(returnStdout: true, script: "kubectl get deployment $user_id-$tool_name-$env.BUILD_ID-$tool_name-viewer  -o jsonpath={.status.replicas}").trim()
    def master_number_ready=sh(returnStdout: true, script: "kubectl get deployment $user_id-$tool_name-$env.BUILD_ID-$tool_name-viewer  -o jsonpath={.status.readyReplicas}").trim()

    /* Workers (Capture) */
    def worker_number_scheduled=sh(returnStdout: true, script: "kubectl get sts $user_id-$tool_name-$env.BUILD_ID-$tool_name-capture  -o jsonpath={.status.replicas}").trim()
    def worker_number_current=sh(returnStdout: true, script: "kubectl get sts $user_id-$tool_name-$env.BUILD_ID-$tool_name-capture  -o jsonpath={.status.currentReplicas}").trim()
    def worker_number_ready=sh(returnStdout: true, script: "kubectl get sts $user_id-$tool_name-$env.BUILD_ID-$tool_name-capture  -o jsonpath={.status.readyReplicas}").trim()

    /* Verifying Result */
    if(master_number_ready==master_number_scheduled) {
      println("Master pods are running")
    } else {
      println("Some or all of the master pods failed")
      error("Some or all of the master pods failed")
    }
    if(worker_number_ready==worker_number_scheduled) {
      println("Worker pods are running")
    } else {
      println("Some or all of the worker pods failed")
      error("Some or all of the worker pods failed")
    }
  }
}

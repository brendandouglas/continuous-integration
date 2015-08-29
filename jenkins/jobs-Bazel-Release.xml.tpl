<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description>Do the Github release of a Bazel binary</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="%{JENKINS_PLUGIN_github}">
      <projectUrl>%{GITHUB_URL}</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <net.uaznia.lukanus.hudson.plugins.gitparameter.GitParameterDefinition plugin="%{JENKINS_PLUGIN_git-parameter}">
          <name>REF_SPEC</name>
          <description></description>
          <uuid>ca709303-ae93-4be2-b9b8-5ab0c19672d1</uuid>
          <type>PT_BRANCH_TAG</type>
          <branch></branch>
          <tagFilter>*</tagFilter>
          <sortMode>NONE</sortMode>
          <defaultValue></defaultValue>
        </net.uaznia.lukanus.hudson.plugins.gitparameter.GitParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM" plugin="%{JENKINS_PLUGIN_git}2.3.5">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <refspec>+refs/heads/*:refs/remotes/origin/* +refs/notes/*:refs/notes/*</refspec>
        <url>%{GITHUB_URL}</url>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>${REF_SPEC}</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class="list"/>
    <extensions>
      <hudson.plugins.git.extensions.impl.CleanBeforeCheckout/>
    </extensions>
  </scm>
  <quietPeriod>5</quietPeriod>
  <assignedNode>deploy</assignedNode>
  <canRoam>false</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.plugins.copyartifact.CopyArtifact plugin="%{JENKINS_PLUGIN_copyartifact}">
      <project>Bazel</project>
      <filter>**/ci/*</filter>
      <target>input</target>
      <excludes>**/ci/bazel</excludes>
      <selector class="hudson.plugins.copyartifact.StatusBuildSelector">
        <stable>true</stable>
      </selector>
      <flatten>true</flatten>
      <doNotFingerprintArtifacts>false</doNotFingerprintArtifacts>
    </hudson.plugins.copyartifact.CopyArtifact>
    <hudson.tasks.Shell>
      <command>#!/bin/bash

export GITHUB_TOKEN=$(cat $GITHUB_TOKEN_FILE)
export GCS_BUCKET=bazel

# URLs
export GIT_REPOSITORY_URL=&quot;%{GITHUB_URL}&quot;

source scripts/ci/build.sh

args=()
for i in input/*; do
  args+=(&quot;$(echo $i | cut -d &quot;=&quot; -f 2)&quot; &quot;$i&quot;)
done

bazel_release &quot;${args[@]}&quot;

export RELEASE_EMAIL_RECIPIENT=%{BAZEL_RELEASE_RECIPIENT}

echo &quot;To: ${RELEASE_EMAIL_RECIPIENT}&quot;
echo &quot;Subject: ${RELEASE_EMAIL_SUBJECT}&quot;
echo &quot;Content: ${RELEASE_EMAIL_CONTENT}&quot;</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers>
    <hudson.plugins.emailext.ExtendedEmailPublisher plugin="%{JENKINS_PLUGIN_email-ext}">
      <recipientList>${ENV, var=&quot;RELEASE_EMAIL_RECIPIENT&quot;}</recipientList>
      <configuredTriggers>
        <hudson.plugins.emailext.plugins.trigger.ScriptTrigger>
          <email>
            <recipientList></recipientList>
            <subject>$PROJECT_DEFAULT_SUBJECT</subject>
            <body>$PROJECT_DEFAULT_CONTENT</body>
            <recipientProviders>
              <hudson.plugins.emailext.plugins.recipients.ListRecipientProvider/>
            </recipientProviders>
            <attachmentsPattern></attachmentsPattern>
            <attachBuildLog>false</attachBuildLog>
            <compressBuildLog>false</compressBuildLog>
            <replyTo>$PROJECT_DEFAULT_REPLYTO</replyTo>
            <contentType>project</contentType>
          </email>
          <triggerScript>!build.getEnvironment(listener).get(&apos;RELEASE_EMAIL&apos;).isEmpty()</triggerScript>
        </hudson.plugins.emailext.plugins.trigger.ScriptTrigger>
      </configuredTriggers>
      <contentType>default</contentType>
      <defaultSubject>${ENV, var=&quot;RELEASE_EMAIL_SUBJECT&quot;}</defaultSubject>
      <defaultContent>${ENV, var=&quot;RELEASE_EMAIL_CONTENT&quot;}</defaultContent>
      <attachmentsPattern></attachmentsPattern>
      <presendScript>$DEFAULT_PRESEND_SCRIPT</presendScript>
      <attachBuildLog>false</attachBuildLog>
      <compressBuildLog>false</compressBuildLog>
      <replyTo>${SENDER_EMAIL}</replyTo>
      <saveOutput>false</saveOutput>
      <disabled>true</disabled>
    </hudson.plugins.emailext.ExtendedEmailPublisher>
  </publishers>
  <buildWrappers/>
</project>
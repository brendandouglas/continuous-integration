<?xml version='1.0' encoding='UTF-8'?>
<!--
  Copyright 2015 The Bazel Authors. All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<matrix-project plugin="{{ variables.JENKINS_PLUGIN_matrix_project }}">
  <actions/>
  <description>Run the full test suite of Bazel.&#xd;
&#xd;
To be run on head and for release branch/tags only</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="{{ variables.JENKINS_PLUGIN_github }}">
      <projectUrl>{{ variables.GITHUB_URL }}</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <net.uaznia.lukanus.hudson.plugins.gitparameter.GitParameterDefinition plugin="{{ variables.JENKINS_PLUGIN_git_parameter }}">
          <name>REF_SPEC</name>
          <description>The branch / tag to build</description>
          <uuid>1ba7864c-b4fb-44b4-8268-31b304798afa</uuid>
          <type>PT_BRANCH_TAG</type>
          <branch></branch>
          <tagFilter>*</tagFilter>
          <sortMode>NONE</sortMode>
          <defaultValue>origin/master</defaultValue>
        </net.uaznia.lukanus.hudson.plugins.gitparameter.GitParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM" plugin="{{ variables.JENKINS_PLUGIN_git }}">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <refspec>+refs/heads/*:refs/remotes/origin/* +refs/notes/*:refs/notes/*</refspec>
        <url>{{ variables.GITHUB_URL }}</url>
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
      <hudson.plugins.git.extensions.impl.AuthorInChangelog/>
    </extensions>
  </scm>
  <assignedNode>deploy</assignedNode>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <concurrentBuild>false</concurrentBuild>
  <axes>
    <hudson.matrix.LabelAxis>
      <name>PLATFORM_NAME</name>
      <values>{% for v in variables.PLATFORMS.split("\n") %}<string>{{ v }}</string>{% endfor %}</values>
    </hudson.matrix.LabelAxis>
    <hudson.matrix.TextAxis>
      <name>JAVA_VERSION</name>
      <values>
        <string>1.7</string>
        <string>1.8</string>
      </values>
    </hudson.matrix.TextAxis>
  </axes>
  <builders>
    <org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder plugin="{{ variables.JENKINS_PLUGIN_conditional_buildstep }}">
      <condition class="org.jenkins_ci.plugins.run_condition.core.ExpressionCondition" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}">
        <expression>^((?!windows).)*$</expression>
        <label>${PLATFORM_NAME}</label>
      </condition>
      <buildStep class="hudson.tasks.Shell">
        <command>{{ imports['//jenkins/jobs:Bazel.unix.sh.tpl'] }}</command>
      </buildStep>
      <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Fail" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}"/>
    </org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder>
    <org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder plugin="{{ variables.JENKINS_PLUGIN_conditional_buildstep }}">
      <condition class="org.jenkins_ci.plugins.run_condition.logic.And" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}">
        <conditions>
          <org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
            <condition class="org.jenkins_ci.plugins.run_condition.core.ExpressionCondition">
              <expression>windows.*</expression>
              <label>${PLATFORM_NAME}</label>
            </condition>
          </org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
          <org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
            <condition class="org.jenkins_ci.plugins.run_condition.core.StringsMatchCondition">
              <arg1>1.8</arg1>
              <arg2>${JAVA_VERSION}</arg2>
              <ignoreCase>false</ignoreCase>
            </condition>
          </org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
        </conditions>
      </condition>
      <buildStep class="hudson.tasks.Shell">
        <command>{{ imports['//jenkins/jobs:Bazel.win.sh.tpl'] }}</command>
      </buildStep>
      <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Fail" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}"/>
    </org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder>
    <org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder plugin="{{ variables.JENKINS_PLUGIN_conditional_buildstep }}">
      <condition class="org.jenkins_ci.plugins.run_condition.core.FileExistsCondition" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}">
        <file>.unstable</file>
        <baseDir class="org.jenkins_ci.plugins.run_condition.common.BaseDirectory$Workspace"/>
      </condition>
      <buildStep class="org.jenkins_ci.plugins.fail_the_build.FixResultBuilder" plugin="{{ variables.JENKINS_PLUGIN_fail_the_build_plugin }}">
        <defaultResultName>UNSTABLE</defaultResultName>
        <success></success>
        <unstable></unstable>
        <failure></failure>
        <aborted></aborted>
      </buildStep>
      <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Unstable" plugin="{{ variables.JENKINS_PLUGIN_run_condition }}"/>
    </org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder>
  </builders>
  <publishers>
    <hudson.tasks.ArtifactArchiver>
      <artifacts>output/ci/**</artifacts>
      <allowEmptyArchive>true</allowEmptyArchive>
      <onlyIfSuccessful>false</onlyIfSuccessful>
      <fingerprint>false</fingerprint>
      <defaultExcludes>true</defaultExcludes>
    </hudson.tasks.ArtifactArchiver>
    {% if variables.SEND_EMAIL == "1" %}
    <hudson.tasks.Mailer plugin="{{ variables.JENKINS_PLUGIN_mailer }}">
      <recipients>{{ variables.BAZEL_BUILD_RECIPIENT }}</recipients>
      <dontNotifyEveryUnstableBuild>false</dontNotifyEveryUnstableBuild>
      <sendToIndividuals>false</sendToIndividuals>
    </hudson.tasks.Mailer>
    {% endif %}
    <hudson.plugins.parameterizedtrigger.BuildTrigger plugin="{{ variables.JENKINS_PLUGIN_parameterized_trigger }}">
      <configs>
        <hudson.plugins.parameterizedtrigger.BuildTriggerConfig>
          <configs>
            <hudson.plugins.parameterizedtrigger.CurrentBuildParameters/>
          </configs>
          <projects>Bazel-Install-Trigger, Bazel-Publish-Site, Bazel-Release-Trigger</projects>
          <condition>UNSTABLE_OR_BETTER</condition>
          <triggerWithNoParameters>false</triggerWithNoParameters>
        </hudson.plugins.parameterizedtrigger.BuildTriggerConfig>
      </configs>
    </hudson.plugins.parameterizedtrigger.BuildTrigger>
  </publishers>
  <buildWrappers>
    <hudson.plugins.build__timeout.BuildTimeoutWrapper>
      <strategy class="hudson.plugins.build_timeout.impl.AbsoluteTimeOutStrategy">
        <timeoutMinutes>240</timeoutMinutes>
      </strategy>
      <operationList>
        <hudson.plugins.build__timeout.operations.FailOperation/>
        <hudson.plugins.build__timeout.operations.WriteDescriptionOperation>
          <description>Timed out</description>
        </hudson.plugins.build__timeout.operations.WriteDescriptionOperation>
      </operationList>
    </hudson.plugins.build__timeout.BuildTimeoutWrapper>
  </buildWrappers>
  <executionStrategy class="hudson.matrix.DefaultMatrixExecutionStrategyImpl">
    <runSequentially>false</runSequentially>
  </executionStrategy>
</matrix-project>

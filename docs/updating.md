#Updating to a new version of Concourse

## Update - now you can update Concourse with Concourse (yo dawg)

The pipeline can be found in `pipeline/concourse-redeploy.yml`

It gets its concourse manifest from an S3 bucket in the same account.
The bucket is managed by terraform (to upload the `concourse.yml` from the root
of this repo).

A caveat of doing updates with a pipeline is that it will update to the latest
versions of *all* releases _and_ stemcells.  When the latter updates the workers
must restart which causes the concourse deployment to stop working for a few
minutes while the pipeline displays as errored in the UI.  However the bosh deploy
continues and the deployment does come back up.

As a result of this, the pipeline is set to never auto-trigger.  If the latest
versions of everything are already deployed the pipeline will return a successful
noop.

### Setting the pipeline

First retrieve the variables file
```
aws s3 cp --region eu-west-1 s3://dachs-setup-variables/redeploy-vars.yml pipeline/vars/redeploy-vars.yml
```
Then set the pipeline (assuming `dachs` is ci.dachs.dog)
```
fly -t dachs set-pipeline -p concourse-redeploy -c pipeline/concourse-redeploy.yml -l pipeline/vars/redeploy-vars.yml
```
Try to make sure only one of these pipelines is ever set at once and only set
it in the main team.  Bosh does lock resources when deploying but I wouldn't
recommend running two of these pipelines simultaneously.

The pipeline can then be unpaused from the web UI and triggered by clicking
the `deploy-concourse` task and pressing the `+` in the top right.

## The old way

As the deployment is managed by BOSH, updating the concourse version is easy and requires no downtime.

The deployment manifest `concourse.yml` will use the latest release that has been uploaded.

When a new version of [Concourse](https://concourse.ci/downloads.html) becomes available you first need to upload the latest release:
```
bosh upload release https://bosh.io/d/github.com/concourse/concourse
```

Now make sure the correct deployment manifest is referenced:
```
bosh deployment concourse.yml
```

And finally deploy:
```
bosh deploy
```

This will take a few minutes to complete.

#Updating to a new version of Garden

Same as above with Concourse but instead run
```
bosh upload release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release
```

#Changing the cloud config

The definitions such as vm types and disk sizes are found in `aws-cloud.yml`.  Upon making edits there, the changes can be deployed by:
```
bosh update cloud-config aws-cloud.yml
bosh deployment concourse.yml
bosh deploy
```

#Changing the deployment

Changes made to `concourse.yml` (such as adding worker vms or changing keys) can be deployed with a simple:
```
bosh deployment concourse.yml
bosh deploy
```
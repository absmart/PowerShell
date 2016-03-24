# Azure Web App with Deployment Slots

This template deploys an Azure Web APp with options to setup a Service Plan, autoscaling for the Service Plan, deployment slots and a storage account for logging.

The template completes the following steps:
 - Creates a storage account that can be used to capture IIS and Application logs from the Web App.
 - Create or modify an existing Service Plan for Azure Web App.
 - Create or modify an existing Azure Web App and define AppSettings, ConnectionStrings.
 - Create or modify Deployment Slots and specify slot specific AppSettings and ConnectionStrings.
 - Create or modify an Autoscale Settings for the Service Plan.
 - Create or modify an Application Insights resource and assign the Web App to it.
 - Create or modify a Traffic Manager resource and assign an Azure endpoint to the Web App.
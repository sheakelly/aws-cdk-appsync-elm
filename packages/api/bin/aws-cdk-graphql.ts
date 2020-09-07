#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "@aws-cdk/core";
import { AppSyncCdkStack } from "../lib/aws-cdk-graphql-stack";

const app = new cdk.App();
new AppSyncCdkStack(app, "AppSyncCdkStack");

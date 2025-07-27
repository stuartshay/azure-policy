# GitHub Actions Workflow Patterns

## Workflow Organization

### Standard Workflow Files
```
.github/
└── workflows/
    ├── terraform-validate.yml     # PR validation
    ├── terraform-plan.yml         # Plan on PR
    ├── terraform-apply.yml        # Deploy infrastructure
    ├── terraform-destroy.yml      # Destroy infrastructure
    ├── cost-monitoring.yml        # Daily cost tracking
    └── drift-detection.yml        # Weekly drift detection
```

## Common Workflow Patterns

### Environment Variables
```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  TF_VAR_environment: "dev"
  TF_VAR_location: "East US"
```

### Standard Job Structure
```yaml
jobs:
  terraform-action:
    runs-on: ubuntu-latest
    environment: development

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
```

## Validation Workflow Pattern

### terraform-validate.yml
```yaml
name: Terraform Validate

on:
  pull_request:
    paths:
      - 'infrastructure/**'
      - '.github/workflows/terraform-*.yml'
  push:
    branches: [ main ]
    paths:
      - 'infrastructure/**'

jobs:
  validate:
    name: Validate Terraform
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Format Check
      run: terraform fmt -check -recursive
      working-directory: infrastructure/terraform

    - name: Terraform Init
      run: terraform init -backend=false
      working-directory: infrastructure/terraform

    - name: Terraform Validate
      run: terraform validate
      working-directory: infrastructure/terraform

    - name: Run tfsec
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        working_directory: infrastructure/terraform
```

## Plan Workflow Pattern

### terraform-plan.yml
```yaml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'infrastructure/**'
    types: [opened, synchronize, reopened]

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    environment: development

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Terraform Init
      run: terraform init
      working-directory: infrastructure/terraform

    - name: Terraform Plan
      id: plan
      run: |
        terraform plan -detailed-exitcode -out=tfplan
        echo "exitcode=$?" >> $GITHUB_OUTPUT
      working-directory: infrastructure/terraform
      continue-on-error: true

    - name: Upload Plan
      uses: actions/upload-artifact@v3
      with:
        name: terraform-plan
        path: infrastructure/terraform/tfplan

    - name: Comment PR
      uses: actions/github-script@v6
      with:
        script: |
          const output = `#### Terraform Plan 📖

          **Exit Code:** ${{ steps.plan.outputs.exitcode }}

          <details><summary>Show Plan</summary>

          \`\`\`terraform
          ${{ steps.plan.outputs.stdout }}
          \`\`\`

          </details>

          *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: output
          })
```

## Apply Workflow Pattern

### terraform-apply.yml
```yaml
name: Terraform Apply

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - staging
        - prod
      confirm:
        description: 'Type "apply" to confirm deployment'
        required: true
        type: string

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  validate-input:
    name: Validate Input
    runs-on: ubuntu-latest
    steps:
    - name: Validate Confirmation
      run: |
        if [ "${{ github.event.inputs.confirm }}" != "apply" ]; then
          echo "❌ Confirmation failed. You must type 'apply' to proceed."
          exit 1
        fi
        echo "✅ Confirmation validated"

  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: validate-input
    environment: ${{ github.event.inputs.environment }}

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Terraform Init
      run: terraform init
      working-directory: infrastructure/terraform

    - name: Terraform Apply
      run: terraform apply -auto-approve
      working-directory: infrastructure/terraform

    - name: Output Summary
      run: |
        echo "## Deployment Summary" >> $GITHUB_STEP_SUMMARY
        echo "- **Environment:** ${{ github.event.inputs.environment }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Triggered by:** ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Timestamp:** $(date)" >> $GITHUB_STEP_SUMMARY
```

## Destroy Workflow Pattern

### terraform-destroy.yml
```yaml
name: Terraform Destroy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to destroy'
        required: true
        type: choice
        options:
        - dev
        - staging
      confirm_destroy:
        description: 'Type "destroy" to confirm'
        required: true
        type: string
      double_confirm:
        description: 'Type environment name again'
        required: true
        type: string

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  validate-destroy:
    name: Validate Destroy Request
    runs-on: ubuntu-latest
    steps:
    - name: Validate Confirmations
      run: |
        if [ "${{ github.event.inputs.confirm_destroy }}" != "destroy" ]; then
          echo "❌ First confirmation failed. You must type 'destroy'."
          exit 1
        fi

        if [ "${{ github.event.inputs.double_confirm }}" != "${{ github.event.inputs.environment }}" ]; then
          echo "❌ Second confirmation failed. You must type the environment name."
          exit 1
        fi

        if [ "${{ github.event.inputs.environment }}" == "prod" ]; then
          echo "❌ Production environment cannot be destroyed via workflow."
          exit 1
        fi

        echo "✅ All confirmations validated"

  destroy:
    name: Terraform Destroy
    runs-on: ubuntu-latest
    needs: validate-destroy
    environment: ${{ github.event.inputs.environment }}

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Terraform Init
      run: terraform init
      working-directory: infrastructure/terraform

    - name: Terraform Destroy
      run: terraform destroy -auto-approve
      working-directory: infrastructure/terraform

    - name: Cleanup Summary
      run: |
        echo "## Destruction Summary" >> $GITHUB_STEP_SUMMARY
        echo "- **Environment:** ${{ github.event.inputs.environment }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Destroyed by:** ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Timestamp:** $(date)" >> $GITHUB_STEP_SUMMARY
        echo "- **Status:** ✅ Infrastructure destroyed" >> $GITHUB_STEP_SUMMARY
```

## Cost Monitoring Pattern

### cost-monitoring.yml
```yaml
name: Cost Monitoring

on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9 AM UTC
  workflow_dispatch:

jobs:
  cost-report:
    name: Generate Cost Report
    runs-on: ubuntu-latest

    steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Get Cost Data
      id: cost
      run: |
        # Get current month costs
        COST=$(az consumption usage list \
          --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
          --end-date $(date +%Y-%m-%d) \
          --query "[?contains(instanceName, 'azurepolicy')].{cost:pretaxCost,currency:currency}" \
          --output tsv | awk '{sum+=$1} END {print sum}')

        echo "current_cost=$COST" >> $GITHUB_OUTPUT

    - name: Create Issue
      if: steps.cost.outputs.current_cost > 50
      uses: actions/github-script@v6
      with:
        script: |
          const cost = '${{ steps.cost.outputs.current_cost }}';
          const title = `🚨 Cost Alert: Monthly spend is $${cost}`;
          const body = `
          ## Cost Alert

          Current monthly spend for Azure Policy infrastructure: **$${cost}**

          ### Recommendations:
          - Review resource utilization
          - Consider scaling down development resources
          - Check for unused resources

          ### Actions:
          - [ ] Review App Service Plan scaling
          - [ ] Check Function App consumption
          - [ ] Verify storage account usage
          - [ ] Consider destroying dev environment if not in use
          `;

          github.rest.issues.create({
            owner: context.repo.owner,
            repo: context.repo.repo,
            title: title,
            body: body,
            labels: ['cost-alert', 'infrastructure']
          });
```

## Security Patterns

### Secret Management
```yaml
# Use GitHub Environments for secret management
environment: development
secrets:
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

### OIDC Authentication (Recommended)
```yaml
permissions:
  id-token: write
  contents: read

steps:
- name: Azure Login (OIDC)
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Error Handling Patterns

### Retry Logic
```yaml
- name: Terraform Apply with Retry
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 30
    max_attempts: 3
    retry_wait_seconds: 60
    command: |
      cd infrastructure/terraform
      terraform apply -auto-approve
```

### Failure Notifications
```yaml
- name: Notify on Failure
  if: failure()
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: `❌ Infrastructure Deployment Failed - ${context.workflow}`,
        body: `
        Workflow: ${context.workflow}
        Run: ${context.runNumber}
        Actor: ${context.actor}

        Please check the workflow logs for details.
        `,
        labels: ['infrastructure', 'failure']
      });
```

## Reusable Workflow Patterns

### Composite Action for Terraform Setup
```yaml
# .github/actions/setup-terraform/action.yml
name: 'Setup Terraform'
description: 'Setup Terraform with Azure authentication'

inputs:
  terraform-version:
    description: 'Terraform version'
    required: false
    default: '1.6.0'

runs:
  using: 'composite'
  steps:
  - name: Setup Terraform
    uses: hashicorp/setup-terraform@v3
    with:
      terraform_version: ${{ inputs.terraform-version }}

  - name: Azure Login
    uses: azure/login@v1
    with:
      creds: ${{ secrets.AZURE_CREDENTIALS }}
```

## Best Practices

### Workflow Security
1. Use GitHub Environments for sensitive operations
2. Implement approval requirements for production
3. Use OIDC instead of service principal secrets when possible
4. Limit workflow permissions to minimum required
5. Use dependabot for action version updates

### Performance Optimization
1. Cache Terraform providers and modules
2. Use matrix builds for multiple environments
3. Implement conditional execution based on changed files
4. Use artifacts for sharing data between jobs

### Monitoring and Alerting
1. Implement cost monitoring workflows
2. Set up drift detection
3. Create failure notification mechanisms
4. Use GitHub Issues for tracking infrastructure changes
5. Implement automated rollback procedures

### Documentation
1. Include workflow descriptions in README
2. Document required secrets and permissions
3. Provide troubleshooting guides
4. Maintain workflow change logs
5. Include cost impact estimates in deployment workflows

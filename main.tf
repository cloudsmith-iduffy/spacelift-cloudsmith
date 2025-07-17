terraform {
  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = "0.0.62"
    }
  }
}

provider "cloudsmith" {}

# Data source to get organization information
data "cloudsmith_organization" "my_organization" {
  slug = "iduffy-demo" # Replace with your organization slug
}

# Create a Cloudsmith repository
resource "cloudsmith_repository" "my_repository" {
  name        = "My Repository"
  namespace   = data.cloudsmith_organization.my_organization.slug_perm
  description = "A repository created with Terraform"
  slug        = "my-repository" # Optional: URL-friendly identifier

  # Optional: Repository type (defaults to Private if not specified)
  # repository_type = "Public"
}

# Get current user for self-admin privileges
data "cloudsmith_user_self" "this" {}

# Get specific org member details
data "cloudsmith_org_member_details" "member1" {
  organization = data.cloudsmith_organization.my_organization.slug
  member       = "iduffy+member1@cloudsmith.io" # Replace with actual email
}

data "cloudsmith_org_member_details" "member2" {
  organization = data.cloudsmith_organization.my_organization.slug
  member       = "iduffy+member2@cloudsmith.io" # Replace with actual email
}

# Create team
resource "cloudsmith_team" "developers" {
  organization = data.cloudsmith_organization.my_organization.slug
  name         = "Developers"
  description  = "Development team"
}

# Add members to team using org member details
resource "cloudsmith_manage_team" "dev_team_members" {
  organization = data.cloudsmith_organization.my_organization.slug
  team_name         = cloudsmith_team.developers.slug

  members {
    user = data.cloudsmith_org_member_details.member1.user_id
    role = "Manager"
  }

  members {
    user = data.cloudsmith_org_member_details.member2.user_id
    role = "Member"
  }
}

# Assign repository privileges
resource "cloudsmith_repository_privileges" "my_repo_privileges" {
  organization = data.cloudsmith_organization.my_organization.slug
  repository   = cloudsmith_repository.my_repository.slug

  # Self-admin for Terraform service account
  service {
    privilege = "Admin"
    slug      = data.cloudsmith_user_self.this.slug
  }

  # Team access
  team {
    privilege = "Write"
    slug      = cloudsmith_team.developers.slug
  }
}

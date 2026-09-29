policy_set "hashibank-stack-governance" {
  policy "eks-approved-versions" {
    source            = "./policies/eks-version-governance.tfpolicy"
    enforcement_level = "soft-mandatory"
  }
}

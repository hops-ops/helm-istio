import datetime
import math
import models.ai.com.ops.hops.helm.v1alpha1 as helmv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# E2E Test for Istiod XRD (Kubernetes-only)
#
# This test uses the Helm provider with ProviderConfig which uses
# injected identity (no credentials needed - runs in-cluster).
# ==============================================================================

# Generate unique name using timestamp to avoid CI conflicts
_now = str(int(math.floor(datetime.ticks())))
_test_name = "e2e-istiod-" + _now

_items = [
    metav1alpha1.E2ETest {
        metadata.name = "istiod-helm"
        spec = {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "None"
            }
            defaultConditions = ["Ready"]
            timeoutSeconds = 1800  # 30 minutes
            cleanupTimeoutSeconds = 600  # 10 minutes
            skipDelete = False

            # ==============================================================
            # extraResources: Helm ProviderConfig with injected identity
            # These are NOT deleted during cleanup
            # ==============================================================
            extraResources = [
                # Helm ProviderConfig - uses in-cluster identity
                # Must use helm.m.crossplane.io to match the Release API
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "InjectedIdentity"
                        }
                    }
                }
            ]

            # ==============================================================
            # manifests: The Istiod XR to test
            # Resources here ARE deleted during cleanup
            # ==============================================================
            manifests = [
                helmv1alpha1.Istiod {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        clusterName = _test_name
                        # labels uses x-kubernetes-preserve-unknown-fields
                        labels = {
                            "hops.ops.com.ai/e2etest" = "true"
                            "hops.ops.com.ai/test-run" = _now
                        }
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        # values uses x-kubernetes-preserve-unknown-fields
                        values = {
                            pilot = {
                                resources = {
                                    requests = {cpu = "10m", memory = "64Mi"}
                                }
                            }
                        }
                    }
                }
            ]
        }
    }
]
items = _items

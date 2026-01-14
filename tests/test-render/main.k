import models.ai.com.ops.hops.helm.v1alpha1 as helmv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for Istiod XRD
#
# Philosophy: Test YOUR API, not the provider's API.
# - render/validate already checks provider schema correctness
# - Tests should verify XRD spec fields produce expected behavior
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders Helm release with name defaulting to XR name
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-helm-release"
        spec = {
            compositionPath = "apis/istiods/composition.yaml"
            xrdPath = "apis/istiods/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Istiod {
                metadata.name = "test-istiod"
                spec.clusterName = "test-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: Custom labels are applied and merged with defaults
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-labels-merged-with-defaults"
        spec = {
            compositionPath = "apis/istiods/composition.yaml"
            xrdPath = "apis/istiods/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Istiod {
                metadata.name = "labeled-istiod"
                spec = {
                    clusterName = "test-cluster"
                    # labels uses x-kubernetes-preserve-unknown-fields, use untyped
                    labels = {team = "platform", environment = "staging"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "labeled-istiod"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/istiod" = "labeled-istiod"
                            team = "platform"
                            environment = "staging"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: overrideAllValues replaces defaults
    # Note: overrideAllValues uses x-kubernetes-preserve-unknown-fields
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "override-all-values"
        spec = {
            compositionPath = "apis/istiods/composition.yaml"
            xrdPath = "apis/istiods/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Istiod {
                metadata.name = "override-test"
                spec = {
                    clusterName = "my-cluster"
                    overrideAllValues = {fullnameOverride = "custom-istiod", pilot = {enabled = True}}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "override-test"
                    spec.forProvider.values = {
                        fullnameOverride = "custom-istiod"
                        pilot = {enabled = True}
                    }
                }
            ]
        }
    }
]

items = _items

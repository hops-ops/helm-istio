import models.ai.com.ops.hops.stacks.v1alpha1 as stacksv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for Istio XRD
#
# Philosophy: Test YOUR API, not the provider's API.
# - render/validate already checks provider schema correctness
# - Tests should verify XRD spec fields produce expected behavior
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders base, istiod, and default gateways
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-all-releases"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test-istio"
                spec.clusterName = "test-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istio-base"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istio-istiod"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istio-istio-ingressgateway"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istio-istio-egressgateway"
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
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "labeled-istio"
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
                        name = "labeled-istio-istiod"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/istiostack" = "labeled-istio"
                            team = "platform"
                            environment = "staging"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: istiod overrideAllValues replaces defaults
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "override-all-values"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "override-test"
                spec = {
                    clusterName = "my-cluster"
                    istiod = {
                        overrideAllValues = {fullnameOverride = "custom-istiod", pilot = {enabled = True}}
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "override-test-istiod"
                    spec.forProvider.values = {
                        fullnameOverride = "custom-istiod"
                        pilot = {enabled = True}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: Explicit gateways override defaults
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "explicit-gateways"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "custom-gw"
                spec = {
                    clusterName = "test-cluster"
                    gateways = [
                        {name = "my-ingress", type = "NodePort"}
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "custom-gw-base"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "custom-gw-istiod"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "custom-gw-my-ingress"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: Egress allowedHosts creates ServiceEntry objects
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "egress-allowed-hosts"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "egress-test"
                spec = {
                    clusterName = "test-cluster"
                    egress = {
                        allowedHosts = ["*.googleapis.com", "api.github.com"]
                    }
                }
            }
            assertResources = [
                # ServiceEntry for wildcard host
                {
                    apiVersion = "kubernetes.crossplane.io/v1alpha2"
                    kind = "Object"
                    metadata.name = "egress-test-egress-wildcard-googleapis-com"
                }
                # ServiceEntry for specific host
                {
                    apiVersion = "kubernetes.crossplane.io/v1alpha2"
                    kind = "Object"
                    metadata.name = "egress-test-egress-api-github-com"
                }
            ]
        }
    }
]

items = _items

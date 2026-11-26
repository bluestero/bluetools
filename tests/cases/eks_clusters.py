"""The eks-clusters part's uninstall: it offers to remove the EKS contexts kx sync added (default
No; --yes keeps them), in a scratch copy of the repo with a scratch kubeconfig."""
import os
import shutil
import subprocess

from fixture import REPO
from term import Term
from bluetools_worlds import aws

CONFIG = """
    apiVersion: v1
    kind: Config
    clusters:
    - cluster: {server: "https://127.0.0.1:1"}
      name: arn:aws:eks:us-east-1:111111111111:cluster/shop-dev-eks
    - cluster: {server: "https://127.0.0.1:2"}
      name: minikube
    contexts:
    - context: {cluster: "arn:aws:eks:us-east-1:111111111111:cluster/shop-dev-eks", user: u1}
      name: shop-dev
    - context: {cluster: minikube, user: u2}
      name: minikube
    current-context: minikube
    users:
    - name: u1
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          command: aws
          args: [eks, get-token, --cluster-name, shop-dev-eks, --region, us-east-1]
          env: [{name: AWS_PROFILE, value: shop-dev}]
    - name: u2
      user: {token: x}
    """


def setup(sb):
    repo = sb.root + "/repo"
    shutil.copytree(REPO, repo, ignore=shutil.ignore_patterns(".git", "layers.lock", "tests", "tasks", "airpr", "*.zip"))
    aws(sb)
    sb.write("~/.kube/config", CONFIG)
    sb.write("~/.config/kx/ignore", "shop-poc\n")
    sb.env.update(KUBECONFIG=sb.path("~/.kube/config"), KX_BASE_KUBECONFIG=sb.path("~/.kube/config"))
    return repo


def test_yes_keeps_the_clusters_and_says_so(sb):
    repo = setup(sb)
    p = subprocess.run([repo + "/uninstall.sh", "--yes", "eks-clusters"], env=sb.env, cwd=sb.home,
                       capture_output=True, text=True, timeout=60, stdin=subprocess.DEVNULL)
    out = p.stdout + p.stderr
    assert p.returncode == 0, out
    assert "kept · your clusters stay" in out, out
    assert "shop-dev" in sb.read("~/.kube/config"), out


def test_yes_to_the_question_removes_only_the_eks_clusters(sb):
    repo = setup(sb)
    t = Term([repo + "/uninstall.sh", "--plain", "eks-clusters"], sb.env, cols=160, rows=40, cwd=sb.home)
    t.wait_for("Go ahead?")
    t.key("y", "enter")
    t.wait_for("Remove the 1 EKS cluster(s)")
    assert "(shop-dev)" in t.text() and "skip list" in t.text(), t.text()
    t.key("y", "enter")
    t.wait_exit()
    cfg = sb.read("~/.kube/config")
    assert "shop-dev" not in cfg and "minikube" in cfg, cfg                      # only kx sync's kind
    assert not os.path.exists(sb.path("~/.config/kx/ignore"))
    assert os.path.exists(sb.path("~/.kube/config.kx-bak")), "kx rm backs the file up first"

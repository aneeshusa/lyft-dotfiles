# Install Nix, packages and configuration
def provision_nix(env, node)
  dotfiles_host_dir = File.dirname(File.dirname(__FILE__))
  dotfiles_guest_dir = '/home/vagrant/workspace/dotfiles'
  node.vm.synced_folder dotfiles_host_dir, dotfiles_guest_dir
  node.vm.provision 'chown-workspace', type: :shell do |shell|
    shell.privileged = true
    shell.inline = <<-EOF
      set -o errexit
      set -o nounset
      set -o pipefail

      chown vagrant:vagrant '#{File.dirname(dotfiles_guest_dir)}'
    EOF
  end
  node.vm.provision 'nix-install', type: :shell do |shell|
    shell.privileged = false
    shell.inline = <<-EOF
      set -o errexit
      set -o nounset
      set -o pipefail

      if ! which nix-env >/dev/null 2>/dev/null; then
          NIX_ENV='#{env}' #{dotfiles_guest_dir}/install
      fi
    EOF
  end
end

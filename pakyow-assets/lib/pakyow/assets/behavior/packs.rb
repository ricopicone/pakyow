# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Packs
        extend Support::Extension

        apply_extension do
          after :initialize do
            config.assets.packs.paths.each do |packs_path|
              Pathname.glob(File.join(packs_path, "*.*")).group_by { |path|
                File.join(File.dirname(path), File.basename(path, File.extname(path)))
              }.to_a.sort { |pack_a, pack_b|
                pack_b[1] <=> pack_a[1]
              }.uniq { |pack_path, _|
                unversioned_pack_path(pack_path)
              }.map { |pack_path, pack_asset_paths|
                [unversioned_pack_path(pack_path), pack_asset_paths]
              }.reverse.each do |pack_path, pack_asset_paths|
                asset_pack = Pack.new(File.basename(pack_path).to_sym, config.assets)

                pack_asset_paths.each do |pack_asset_path|
                  if config.assets.extensions.include?(File.extname(pack_asset_path))
                    asset_pack << Asset.new_from_path(pack_asset_path, config: config.assets)
                  end
                end

                self.pack << asset_pack.finalize
              end
            end
          end
        end

        def unversioned_pack_path(pack_path)
          pack_path.split("@", 2)[0]
        end
      end
    end
  end
end

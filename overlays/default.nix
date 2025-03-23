{
  self,
  system,
  ...
}: {
  lutris = final: prev: {
    inherit (self.packages.${system}) lutris;
  };
}

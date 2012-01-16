class Symbol
  def <=>(other_symbol)
    self.to_s <=> other_symbol.to_s
  end
end


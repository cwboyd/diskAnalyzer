
FILENAME = "/mnt/images/run1/recup_dir.56/f277077744.xml"
#FILENAME = "/mnt/images/run1/recup_dir.56/recover02.bin"
#BLOCKSIZE = 4096 * 1024
#BLOCKSIZE = 4096 * 4096
BLOCKSIZE = 128 * 1024
last_non_null_index = -1
EVERY_N_BLKS = 10

class Array
  def all_null?
    self.each do |elt|
      return false unless (elt == 0)
    end
    return true
  end
end

class Integer
  def to_comma_s
    return to_s.gsub(/\B(?=(...)*\b)/, ',')
  end
end

class String
  def each_byte_with_index
    index = 0
    self.each_byte do |byte|
      yield byte, index
      index += 1
    end
  end
end

class File

  def each_block_with_index(buffer, blocksize = BLOCKSIZE)
    index = 0
    block_index = 0
    size = File.size(FILENAME)

    while index < size do
      block = self.sysread(blocksize, buffer)
      return index if block.nil?
      yield block, index, block_index
      index += block.length
      block_index += 1
    end
  end

  def each_byte_with_index(blocksize = BLOCKSIZE)
    index = 0
    self.each_byte do |byte|
      yield byte, index
      index += 1
    end
  end
end

File.open(FILENAME, "rb") do |file|
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  buffer = String.new(capacity: BLOCKSIZE)

  file.each_block_with_index(buffer) do |block, index, block_index|

    if (block_index % EVERY_N_BLKS == 0) then
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = end_time - start_time
      rate = (index.to_f + block.size.to_f) / elapsed.to_f
      rate = rate.to_i
      STDOUT.print "\rRead block at index #{index.to_comma_s} (rate = #{rate.to_comma_s} MB/s)"
    end

    block.each_byte_with_index do |byte, offset|
      next if byte == 0
      STDOUT.puts if offset == 0
      STDOUT.puts "Found non-NULL byte #{byte} at index #{index}"
    end
  end
end



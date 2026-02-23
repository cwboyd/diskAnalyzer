
FILENAME = "/mnt/images/run1/recup_dir.56/f277077744.xml"
#FILENAME = "/mnt/images/run1/recup_dir.56/recover02.bin"
#BLOCKSIZE = 4096 * 1024
#BLOCKSIZE = 4096 * 4096
BLOCKSIZE = 128 * 1024
last_non_null_index = -1

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

class File
  EVERY_N_BLKS = 100

  def each_block_byte_with_index(blocksize = BLOCKSIZE)
    index = 0
    blk_index = 0
    size = File.size(FILENAME)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    buffer = String.new(capacity: BLOCKSIZE)

    while index < size do
      #start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block = self.sysread(blocksize, buffer)
      blk_index += 1
      return index if block.nil?

      if blk_index == EVERY_N_BLKS
        blk_index = 0
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed = end_time - start_time
        rate = (index.to_f + block.size.to_f) / elapsed.to_f
        #rate = rate / 1_000_0000
        rate = rate.to_i
        STDOUT.print "\rRead block at index #{index.to_comma_s} (rate = #{rate.to_comma_s} MB/s)"
      end

      offset = 0
      index += block.length
#      block.each_byte do |byte|
#        yield byte, index, offset
#        index += 1
#        offset += 1
#      end
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
  #file.each_byte_with_index do |byte, index, offset|
  file.each_block_byte_with_index do |byte, index, offset|
    next if byte == 0
    puts if offset == 0
    last_non_null_index = index
    puts "Found non-NULL byte #{byte} at index #{index}"
  end
end





DIRNAME = "/mnt/images/run1/recup_dir.56/"
BASENAME = "f277077744"
FILENAME = DIRNAME + BASENAME + ".xml" 
RECOVERY_ROOT = DIRNAME + "recovered-" 
BLOCKSIZE = 4096 * 4096

class Integer
  def to_comma_s
    return to_s.gsub(/\B(?=(...)*\b)/, ',')
  end
end

class File
  def each_block_byte_with_index(blocksize = BLOCKSIZE)
    index = self.tell()
    size = File.size(FILENAME)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    while index < size do
      block = self.read(blocksize)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = end_time - start_time
      return index if block.nil?
      rate = (index.to_f + block.size.to_f) / elapsed.to_f
      #rate = rate / 1_000_0000
      rate = rate.to_i

      STDOUT.print "\rRead block at index #{index.to_comma_s} (rate = #{rate.to_comma_s} B/s)"
      offset = 0
      block.each_byte do |byte|
        yield byte, index, offset
        index += 1
        offset += 1
      end
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

  recovery = nil
  file.seek(98_000_000_000)

  
  file.each_block_byte_with_index do |byte, index, offset|
   
#    puts "index #{index} => byte #{byte}"
#    exit() if index > 32_000

    if byte == 0 then
      unless recovery.nil? then
        puts "closing recovery at index #{index}"
        recovery.close
        recovery = nil
      end
      next
    end

    puts if offset == 0

    puts "Found non-NULL byte #{byte} at index #{index}"
    
    if recovery.nil? then
      recovery_filename = RECOVERY_ROOT + index.to_s + ".bin"
      recovery = File.open(recovery_filename, "w+b")
    end

    recovery.write([byte].pack("C"))

  end
end



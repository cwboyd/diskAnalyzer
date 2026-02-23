
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

class String
  ALL_NULL_REGEXP = /^[\0]*$/
  def all_null?
    return ALL_NULL_REGEXP.match?(self)
  end
  def each_byte_with_index(starting_index)
    offset = 0
    self.each_byte do |byte|
      yield byte, starting_index + offset
      offset += 1
    end
  end
end

class Integer
  def to_comma_s
    return to_s.gsub(/\B(?=(...)*\b)/, ',')
  end
end

class File

  def each_block_with_index(blocksize = BLOCKSIZE)
    index = 0
    block_index = 0
    size = File.size(FILENAME)
    buffer = String.new(capacity: BLOCKSIZE)

    while index < size do
      block = self.sysread(blocksize, buffer)
      #block = self.read(blocksize, buffer)
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


#FILENAME = "/mnt/images/run1/recup_dir.56/f277077744.xml"
#FILENAME = "/mnt/images/run1/recup_dir.56/recover02.bin"
FILENAME = ARGV[0]
FILENAME_SIZE = File.size(FILENAME)
DIRNAME = FILENAME.split('/')[0..-2].join('/')
BASEFILENAME = FILENAME.split('/')[-1]
OFFSETS_FILENAME = [DIRNAME, '/', 'offsets-', BASEFILENAME].join('')

STDERR.puts("Analyzing: #{FILENAME} (size: #{FILENAME_SIZE.to_comma_s})")
STDERR.puts("Writing offsets file: #{OFFSETS_FILENAME}")
STDERR.puts

START_TIME = Process.clock_gettime(Process::CLOCK_MONOTONIC)


File.open(FILENAME, "rb") do |file|
  File.open(OFFSETS_FILENAME, "w") do |offsets_file|
    file.each_block_with_index do |block, starting_index, block_index|

      if (block_index % EVERY_N_BLKS == 0) then
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - START_TIME
        rate = (starting_index.to_f + block.size.to_f) / elapsed.to_f
        rate = rate.to_i.to_comma_s
        percent = 100.0 * starting_index.to_f / FILENAME_SIZE.to_f 
        percent = percent.to_i
        STDERR.print "\rRead block at index #{starting_index.to_comma_s} (rate = #{rate} B/s, progress = #{percent}%)"
      end

      next if block.all_null?

      block.each_byte_with_index(starting_index) do |byte, index|
        next if byte == 0
        offsets_file.puts "Found non-NULL byte #{byte} (0x#{byte.to_s(16).upcase}) at index #{index}"
      end
    end
  end
end


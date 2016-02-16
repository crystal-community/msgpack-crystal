guard 'process', :name => 'Spec', :command => 'crystal spec'  do
  watch(/spec\/(.*).cr$/)
  watch(/src\/(.*).cr$/)
end

guard 'process', :name => 'Worksheet', :command => 'crystal run private/worksheet.cr' do
  watch(/src\/(.*).cr$/)
  watch('worksheet.cr')
end

guard 'process', :name => 'Format', :command => 'crystal tool format' do
  watch(/(.*).cr$/)
end

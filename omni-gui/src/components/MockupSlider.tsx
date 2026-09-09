
export const MockupSlider = ({ checked, disabled, onChange }: { checked: boolean, disabled: boolean, onChange: (val: boolean) => void }) => {
  return (
    <div 
      className={`relative inline-block w-12 h-6 align-middle select-none transition duration-200 ease-in ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`} 
      onClick={() => !disabled && onChange(!checked)}
    >
      <div className={`absolute block w-6 h-6 rounded-full bg-white border-[3px] appearance-none z-10 transition-all duration-300 top-0 ${checked ? 'right-0 border-green-500' : 'left-0 border-gray-300 dark:border-gray-600'}`}></div>
      <div className={`block overflow-hidden h-6 rounded-full transition-colors duration-300 ${checked ? 'bg-green-500' : 'bg-gray-200 dark:bg-gray-700'}`}></div>
    </div>
  )
}

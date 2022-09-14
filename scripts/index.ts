 


import { generateSignatures } from './generateSignatures'
//import { matchOrder } from './matchOrder'

 
const taskMap: any = {
  
  callExecute,
  submitDiscrete,
  acceptDiscrete,
  fetchCraResponse,
  approveMarket
//  matchOrder
}

async function init(): Promise<void> {
  const args = process.argv.slice(2)

  await runTask(args)
}
 

async function runTask(args: string[]): Promise<void> {
  const taskName = args[0]

  const taskMethod = taskMap[taskName]

  if (typeof taskMethod == 'undefined') throw new Error('unknown task')

  await taskMethod()

  console.log(`Task '${taskName}' complete.`)
}

// eslint-disable-next-line @typescript-eslint/no-floating-promises
init()
